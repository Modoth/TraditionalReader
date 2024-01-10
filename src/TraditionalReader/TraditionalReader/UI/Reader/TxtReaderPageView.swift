//
//  TxtReaderPageView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/20.
//

import AppCommon
import SwiftUI

#Preview {
    class TxtReaderPageViewPreviewModel: ObservableObject {
        @Published var pager: AnyObject?
    }
    return StateView(TxtReaderPageViewPreviewModel()) { state in
        TxtReaderPageView(
            page: FileReaderPage(
                name: "荀子",
                url: (Bundle.main.resourceURL?.appending(components: "previewdata", "荀子.txt"))!,
                width: nil, height: nil, page: 0, position: 0..<1000),
            pager: state.pager,
            onPager: state.pager != nil
                ? nil
                : { p in
                    DispatchQueue.main.async {
                        state.pager = p.shared
                    }
                }
        )
    }.usePreviewServices()
}

struct TxtReaderPageView: UpdatableViewBase, FileReaderPageView {
    let pager: (any TxtPager)?
    let onPager: ((BookReaderPager) -> Void)?
    let onClick: (() -> Void)?

    init(
        page: FileReaderPage,
        pager: AnyObject?,
        onPager: ((BookReaderPager) -> Void)? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.page = page
        self.onPager = onPager
        self.onClick = onClick
        self.pager = pager as? (any TxtPager)? ?? nil
    }

    @ObservedObject var page: FileReaderPage
    @State var content: String = ""
    @State var pageListener: UUID? = nil

    var updateBys: [(any Equatable)?]? {
        [
            content, page.width, page.height, page.position, page.page, page.maxPage,
            page.side,
            onPager != nil,
        ]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        let needMeasure = onPager != nil || page.width == nil || page.height == nil
        let onSize = needMeasure ? updateSize : nil
        let Content = {
            TxtPageV(
                content,
                title: page.name, chapter: nil, page: page.page ?? 0,
                totalPage: page.maxPage == Int.max ? nil : page.maxPage,
                pageSide: page.side,
                fontSize: Self.fontStyle.fontSize,
                width: page.width,
                height: page.height,
                vertical: true,
                onSize: onSize
            )
        }
        //        Group {
        //            if page.side == .both {
        //                Content().aspectRatio(210 / 297, contentMode: .fit)
        //            } else {
        //                Content()
        //            }
        //        }
        Content()
            .onAppear {
                loadContent()
            }.onPropertyChange(of: page.position) { pos in
                loadContent()
            }
            .onDisappear {
                unregisterPager()
            }
            .environmentOo(Self.tags)
            .environmentOo(Self.charOptions)
            .environmentOo(Self.textDirection)
            .environmentOo(FormattedTextV.MissingChar(char: "□", foreground: .accentColor))
            .environmentOo(Self.fontStyle)
    }

    func unregisterPager() {
        guard let pager = pager else {
            return
        }

        if pageListener != nil {
            pager.unregister(id: pageListener!)
        }
        pageListener = nil
    }
    func loadContent() {
        if page.width == nil || page.height == nil || page.position == nil || page.page == nil {
            return
        }
        content = ""
        guard let pager = pager else {
            return
        }
        content = pager.getPageContent(Int(page.page!))
    }

    func updateSize(w: Int, h: Int) {
        if onPager != nil {
            DispatchQueue.main.async {
                let pager: TxtPager = locate()
                tryDo {
                    onPager!(
                        BookReaderPager(
                            width: w, height: h,
                            getPageForInitPosition: {
                                pos, approximatePosition, minPagesCount, setPage in
                                try? pager.config(
                                    file: page.url,
                                    initPosition: pos,
                                    approximatePosition: approximatePosition,
                                    width: w, height: h,
                                    minPagesCount: minPagesCount,
                                    layoutOption: TxtLayoutOption(
                                        tags: Self.tags,
                                        ignoreChars: Self.charOptions.ignoreChars,
                                        halfChars: Self.charOptions.halfChars, sizes: Self.smallFont
                                    ))
                                return pager.getPage(0) { (async, range, totalRange) in
                                    if async {
                                        setPage(0, range, totalRange, true)
                                    } else {
                                        DispatchQueue.main.async {
                                            setPage(0, range, totalRange, true)
                                        }
                                    }
                                }
                            },
                            getPositionForPage: { (pIdx, setPos: @escaping (Range<Int>) -> Void) in
                                return pager.getPage(pIdx) { (async, range, _) in
                                    if async {
                                        setPos(range)
                                    } else {
                                        DispatchQueue.main.async {
                                            setPos(range)
                                        }
                                    }
                                }
                            },
                            getMinPage: { setMin in
                                return pager.getMinPage { (async, minPage) in
                                    if async {
                                        setMin(minPage)
                                    } else {
                                        DispatchQueue.main.async {
                                            setMin(minPage)
                                        }
                                    }
                                }
                            },
                            getMaxPage: { setMax in
                                return pager.getMaxPage { (async, maxPage) in
                                    if async {
                                        setMax(maxPage)
                                    } else {
                                        DispatchQueue.main.async {
                                            setMax(maxPage)
                                        }
                                    }
                                }
                            },
                            unregisterEvent: { id in
                                pager.unregister(id: id)
                            },
                            shared: pager
                        )
                    )
                }
            }
        } else {
            DispatchQueue.main.async {
                if page.width == nil {
                    page.width = w
                }
                if page.height == nil {
                    page.height = h
                }
                loadContent()
            }
        }
    }

    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    static let imagePath = Bundle.main.path(forResource: "bgs/bg1.jpeg", ofType: nil)!
    static var fontStyle: FormattedTextV.Style = {
        let font = UIFont.preferredFont(
            forTextStyle: (UIDevice.current.userInterfaceIdiom == .pad)
                ? .title1 : .title2)
        return FormattedTextV.Style(
            fontSize: font.pointSize,
            fontNames: [
                "TW-Kai", "TW-Kai-Ext-B", "TW-Kai-Plus",
            ].map { ($0, nil) },
            foreground: .black.opacity(0.8),
            smallFont: (8, 6))
    }()
    static let tags: [Character: FormattedTextV.Tag] = Dictionary(
        uniqueKeysWithValues: [
            FormattedTextV.Tag(open: "【", close: "】").with(\.foreground, .black.opacity(0.6))
        ].map { ($0.open, $0) })
    static let smallFont = (8, 6)
    static let charOptions: FormattedTextV.CharsOptions = FormattedTextV.CharsOptions()
        .with(
            \.map,
            [
                "“": "﹃",
                "”": "﹄",
                "‘": "﹁",
                "’": "﹂",
            ]
        )
        .with(
            \.anchors,
            Dictionary(uniqueKeysWithValues: "。.，,、；;".map { ($0, .topTrailing) })
        )
        .with(
            \.rotates,
            Set(
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789([{<『【「《>}])》」】』'\"？?！!：:"
            )
        )

        .with(
            \.ignoreChars,
            Set(
                "，《。》/？；：‘’“”、｜『』！@#¥%……&*（）"
            )
        )
        .with(
            \.halfChars,
            Set(
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
            ))
    static let textDirection: FormattedTextV.TextDirection = .vertical
}
