//
//  PdfReaderPageView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/24.
//

import AppCommon
import Foundation
import PDFKit
import SwiftUI

struct PdfReaderPageView: ViewBase, FileReaderPageView {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var tapHandler: OO<TagHandler>

    @ObservedObject var page: FileReaderPage
    let onPager: ((BookReaderPager) -> Void)?
    let onClick: (() -> Void)?
    init(
        page: FileReaderPage,
        pager: AnyObject?,
        onPager: ((BookReaderPager) -> Void)?,
        onClick: (() -> Void)?
    ) {
        self.page = page
        self.onPager = onPager
        self.onClick = onClick
    }

    @State var doc: PDFDocument? = nil
    @GestureState var fingerLocation: CGPoint? = nil

    var body: some View {
        let _ = Self._printTrace()
        GeometryReader { proxy in
            HStack {
                if doc != nil {
                    PdfPageV(
                        doc: doc!,
                        page: min(
                            Int(page.position?.lowerBound ?? 0), (page.maxPage ?? Int.max) - 1)
                    ).gesture(
                        ExclusiveGesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    tapHandler.value.onTap?(value.location, proxy.size)
                                },
                            DragGesture(minimumDistance: 0, coordinateSpace: .local).updating(
                                $fingerLocation
                            ) {
                                (value, _, _) in
                                tapHandler.value.onDrag?(
                                    value.location, value.startLocation, proxy.size, false)
                            }
                            .onEnded { value in
                                tapHandler.value.onDrag?(
                                    value.location, value.startLocation, proxy.size, true)
                            }
                        )
                    )
                }
            }
        }
        .onAppear {
            guard let doc = PDFDocument(url: page.url) else {
                return
            }
            self.doc = doc
            let totalPage = doc.pageCount
            onPager?(
                BookReaderPager(
                    width: 0,
                    height: 0,
                    getPageForInitPosition: { pos, _, _, setPage in
                        setPage(pos, pos..<pos + 1, 0..<totalPage, false)
                        return nil
                    },
                    getPositionForPage: { page, setPos in
                        setPos(page..<page + 1)
                        return nil
                    },
                    getMinPage: { setMin in
                        setMin(0)
                        return nil
                    },
                    getMaxPage: { setMax in
                        setMax(totalPage)
                        return nil
                    },
                    unregisterEvent: { _ in

                    },
                    shared: nil
                ))
        }

    }
}

#Preview {
    PdfReaderPageView(
        page: FileReaderPage(
            name: "荀子",
            url: (Bundle.main.resourceURL?.appending(components: "previewdata", "荀子.pdf"))!,
            width: nil, height: nil, page: 0, position: 0..<1000), pager: nil,
        onPager: nil, onClick: nil)
}
