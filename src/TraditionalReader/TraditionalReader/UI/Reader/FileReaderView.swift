//
//  FileReaderView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/25.
//

import AppCommon
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FileReaderView: UpdatableViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let name: String
    let url: URL
    let fileType: FileType

    let onClick: (() -> Void)?
    let onPositionChanged: ((Int) -> Void)?
    let initPosition: Int
    init(
        name: String,
        url: URL,
        fileType: FileType,
        position: Int,
        onClick: (() -> Void)? = nil,
        onPositionChanged: ((Int) -> Void)? = nil
    ) {
        self.name = name
        self.url = url
        self.fileType = fileType
        self.onClick = onClick
        self.onPositionChanged = onPositionChanged
        self.initPosition = position
    }

    private func onRelativeSizeChanged(_ size: ReadingPanelRelativeSize) {
        self.pagesCount =
            size.isLandscape == true
                && size.identity
            ? 2 : 1
    }

    @EnvironmentObject var relativeSize: OO<ReadingPanelRelativeSize>
    @State var pagesCount: Int = 1
    @State var firstPosition: Range<Int>? = nil
    @State var lastPosition: Range<Int>? = nil
    @State var totalPosition: Range<Int>? = nil
    @State var selection: (content: String, range: CGRect, horizontal: Bool, cancle: () -> Void)? =
        nil
    @State var selectionQuery: String? = nil
    @State var presentatingPopup = false
    @State var pagesInfo:
        (pager: BookReaderPager, pages: [FileReaderPage], totalPage: FileReaderPage)? = nil

    var updateBys: [(any Equatable)?]? {
        [
            currentPosition, floatingMenu,
            presentatingPopup, selection?.content, selection?.range, relativeSize%!,
            pagesInfo?.pages, UUID(),
        ]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        let padding = (horizontal: 10.0, halfVertical: 10.0)
        PreventUpdate(pagesInfo?.pages) {
            HStack(spacing: 0) {
                if pagesInfo == nil {
                    ForEach(Array(0..<pagesCount), id: \.self) { i in
                        AnyView(
                            fileType.view.init(
                                page: createPage(i),
                                pager: nil,
                                onPager: i == 0 ? updatePager : nil, onClick: nil)
                        )
                        .padding(.vertical, padding.halfVertical)
                        .padding(.leading, padding.horizontal).opacity(0)
                        if i != pagesCount - 1 {
                            Divider()
                        }
                    }
                } else if let pages = pagesInfo?.pages {
                    ForEach(pages.reversed(), id: \.self) { page in
                        let side = page.side
                        Group {
                            PreventUpdate(page, page.side) {
                                AnyView(
                                    fileType.view.init(
                                        page: page,
                                        pager: pagesInfo?.pager.shared,
                                        onPager: nil,
                                        onClick: onClick
                                    )
                                )

                                .padding(.vertical, padding.halfVertical)
                                .padding(.leading, side == .left ? padding.horizontal : 0)
                                .padding(.trailing, side == .right ? padding.horizontal : 0)
                                .padding(
                                    .horizontal,
                                    (side == .none || page.side == .both)
                                        ? padding.horizontal / 2 : 0
                                )
                                //                                .background {
                                //                                    if side == .both {
                                //                                        Rectangle().fill(
                                //                                            .white.shadow(.drop(radius: 1)))
                                //                                    }
                                //                                }
                            }
                            if page != pages.first {
                                Divider()
                            }
                        }
                    }
                }
            }
        }.overlay {
            ZStack {
                contextMenu
                popup
            }
        }.preference(
            key: ReadingPanelFloatItemKey.self,
            value: floatingMenu ?? []
        )
        .onPropertyChange(of: relativeSize) { size in
            onRelativeSizeChanged(size%!)
            pagesInfo = nil
        }
        .onAppear {
            onRelativeSizeChanged(relativeSize%!)
            floatingMenu =
                floatingMenu ?? [
                    ReadingPanelFloatItem(alignment: .bottom) {
                        AnyView(menu)
                    }
                ]
        }.environmentOo(
            TagHandler().with(
                \.onTap,
                { loc, size in
                    onTap(loc, size)
                }
            ).with(
                \.onDrag,
                { loc, sloc, size, end in
                    if end {
                        let offset = loc.x - sloc.x
                        if abs(offset) > 0.1 * size.width {
                            goto((offset > 0 ? pagesCount : -pagesCount))
                        }
                    }
                }
            ).with(
                \.onSelection,
                { selection in
                    self.selection = selection
                    selectionQuery = selection?.0
                    self.presentatingPopup = false
                }
            )
        )
    }

    @State var floatingMenu: [ReadingPanelFloatItem]? = nil

    @ViewBuilder
    private var menu: some View {
        SliderV(value: $currentPosition) { newValue in
            if let total = totalPosition?.upperBound,
                let currentStart = firstPosition?.lowerBound,
                let currentEnd = lastPosition?.upperBound
            {
                goto(
                    position: Int(
                        newValue
                            * Double(total - currentEnd + currentStart)))

            }
        }
        .rotationEffect(.init(degrees: 180))
    }

    @State var currentPosition: Double? = nil

    private func updateCurrentPosition() {
        if let total = totalPosition?.upperBound,
            let currentStart = firstPosition?.lowerBound,
            let currentEnd = lastPosition?.upperBound
        {
            DispatchQueue.main.async {
                currentPosition =
                    Double(currentStart) / Double(total - currentEnd + currentStart)
            }
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        if !presentatingPopup, let content = selection?.content, let range = selection?.range,
            let _ = selection?.horizontal
        {
            GeometryReader { proxy in
                let centerX = (range.maxX + range.minX) / 2 - proxy.frame(in: .global).minX
                let centerY = (range.maxY + range.minY) / 2 - proxy.frame(in: .global).minY
                HStack {
                    VStack {
                        PreventUpdate(content, range) {
                            HStack {
                                HStack {
                                    Button("Dictionary") {
                                        presentatingPopup = true
                                    }
                                    Divider()
                                    Button("Copy") {
                                        UIPasteboard.general.setValue(
                                            content,
                                            forPasteboardType: UTType.plainText.identifier)
                                        selection!.cancle()
                                    }
                                }
                                .padding(5)
                                .padding(.horizontal, 5)
                                .background(.background)
                                .clipShape(.rect(cornerSize: .init(width: 5, height: 5)))
                                .shadow(radius: 5)
                            }.offset(CGSize(width: 0, height: -20))
                                .fixedSize()
                                .frame(width: 0, height: 0, alignment: .center)
                        }
                        .background(.green.opacity(0.5))
                        .offset(CGSize(width: centerX, height: centerY))
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var popup: some View {
        PreventUpdate(presentatingPopup, selection?.content) {
            VStack {
                Spacer()
                DictsView(key: $selectionQuery).background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .padding()
                    .aspectRatio(297 / 210, contentMode: .fit)
                Spacer()
            }.opacity((presentatingPopup && selection?.content != nil) ? 1 : 0)
        }
    }

    private func createPage(_ pageMod: Int = 0) -> FileReaderPage {
        return FileReaderPage(
            name: name, url: url, minPage: pagesInfo?.totalPage.minPage,
            maxPage: pagesInfo?.totalPage.maxPage,
            side: calculateSide(pageMod)
        )
    }

    private func calculateSide(_ pageMod: Int) -> FileReaderPageSide {
        if pagesCount == 2 {
            return pageMod % 2 == 0 ? .right : .left
        }
        if relativeSize%!.identity && pagesCount == 1 {
            return .both
        }
        return .none
    }

    private func updatePageSide(_ p: FileReaderPage) {
        p.side = calculateSide(p.page ?? 0)
    }

    private func goto(position: Int) {
        guard let (pager, pages, totalPage) = pagesInfo else {
            return
        }
        goto(
            pager: pager, pages: pages, totalPage: totalPage, position: position,
            approximatePosition: true)
    }

    private func updatePager(pager: BookReaderPager) {
        let pages = Array(0..<pagesCount).map { i in createPage(i) }
        let totalPage = createPage()
        let position = firstPosition?.lowerBound ?? initPosition
        goto(pager: pager, pages: pages, totalPage: totalPage, position: position)
        pagesInfo = (pager, pages, totalPage)
    }

    private func goto(
        pager: BookReaderPager, pages: [FileReaderPage], totalPage: FileReaderPage, position: Int,
        approximatePosition: Bool = false
    ) {
        totalPage.minPage = nil
        totalPage.maxPage = nil
        createPage().setInitPosition(
            position: position, approximatePosition: approximatePosition, minPagesCount: pagesCount,
            pager: pager
        ) {
            idx, _, totalPosition, relativePage in
            let startPage = (idx / pagesCount) * pagesCount
            self.totalPosition = totalPosition
            updateCurrentPosition()
            for (di, p) in pages.enumerated() {
                p.relativePage = relativePage
                p.setIdx(idx: startPage + di, pager: pager) { pos in
                    updatePageSide(p)
                    if di == 0 {
                        firstPosition = pos
                        updateCurrentPosition()
                        onPositionChanged?(pos.lowerBound)
                    }
                    if di == pagesCount - 1 {
                        lastPosition = pos
                        updateCurrentPosition()
                    }
                }
            }
        }

        totalPage.setAsMin(pager) { tpage in
            pages.forEach { $0.minPage = tpage }
        }
        totalPage.setAsMax(pager) { tpage in
            pages.forEach { $0.maxPage = tpage }
        }
    }

    private func goto(_ pId: Int) {
        guard let (pager, pages, totalPage) = pagesInfo, let currentPage = pages.first?.page else {
            return
        }
        var page = currentPage + pId
        page = min(
            (totalPage.maxPage ?? Int.max) - 1, max((totalPage.minPage ?? Int.min) + 1, page))
        for (di, p) in pages.enumerated() {
            p.setIdx(idx: page + di, pager: pager) { pos in
                updatePageSide(p)
                if di == 0 {
                    firstPosition = pos
                    updateCurrentPosition()
                    onPositionChanged?(pos.lowerBound)
                }
                if di == pagesCount - 1 {
                    lastPosition = pos
                    updateCurrentPosition()
                }
            }
        }
    }

    private func onTap(_ loc: CGPoint, _ size: CGSize) {
        if loc.x <= size.width * 1 / 3 {
            goto(pagesCount)
            return
        }
        if loc.x >= size.width * 2 / 3 {
            goto(-pagesCount)
            return
        }

        if loc.y <= size.height * 1 / 3 {
            goto(-pagesCount)
            return
        }

        if loc.y >= size.height * 2 / 3 {
            goto(pagesCount)
            return
        }
        onClick?()
    }
}

#Preview {
    FileReaderView(
        name: "荀子",
        url: (Bundle.main.resourceURL?.appending(components: "previewdata", "荀子.txt"))!,
        fileType: .txt, position: 0
    )
    .environmentOo(ReadingPanelRelativeSize(x: 1, y: 1, isLandscape: nil))
    .usePreviewServices()
}
