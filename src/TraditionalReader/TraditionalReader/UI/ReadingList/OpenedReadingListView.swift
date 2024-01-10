//
//  OpenedReadingListView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/13.
//

import AppCommon
import SwiftUI
import WCDBSwift

extension ReadingPanelMenuItem: ArrayOrElement {}

struct OpenedReadingListView: UpdatableViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    static let maxPanels = 3

    let readingList: ReadingList
    let onClose: (() -> Void)?

    init(_ readingList: ReadingList, onClose: (() -> Void)? = nil) {
        self.readingList = readingList
        self.onClose = onClose
    }

    @State var panels: [ReadingPanel]? = nil
    @State var focusedPanel: ReadingPanel? = nil
    @State var orientation = UIDevice.current.orientation

    var updateBys: [(any Equatable)?]? {
        [panels, orientation]
    }

    var forceUpdateBy: UUID? {
        readingList.id
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        HStack {}.fullScreenCover(
            isPresented: .constant(true),
            content: {
                if let panels = panels {
                    GeometryReader { p in
                        let canClose = onClose != nil
                        let canCreate = panels.count < Self.maxPanels
                        let multiPanels = panels.count > 1
                        let (relativeSize, width, height, rows, edges) = getOrientationConfig(
                            p, panels)
                        LazyHGrid(rows: rows, spacing: 0) {
                            ForEach(panels, id: \.id) { panel in
                                ReadingPanelView(
                                    readingList, panel,
                                    menu: .from {
                                        if canClose { closeMenuItem }
                                        if canCreate { createPanelMenuItem(panel) }
                                        if multiPanels {
                                            closePanelMenuItem(panel)
                                            closeOthersMenuItem(panel)
                                        }
                                    },
                                    focusedTag: $focusedPanel
                                ).environmentOo(relativeSize(panel.size))
                                    .border(
                                        .black.opacity(0.2), width: 0.5,
                                        edges: panel != panels.last ? edges : []
                                    )
                                    .frame(
                                        width: width(panel.size),
                                        height: height(panel.size)
                                    )
                                    .clipped()
                            }
                        }
                    }.deviceOrientation($orientation)
                } else {
                    HStack {}.onAppear(perform: loadData)
                }
            }
        )
    }

    private func getOrientationConfig(_ p: GeometryProxy, _ panels: [ReadingPanel]) -> (
        (ReadingPanelSize) -> ReadingPanelRelativeSize,
        (ReadingPanelSize) -> CGFloat?,
        (ReadingPanelSize) -> CGFloat?,
        [GridItem], [Edge]
    ) {
        let total = panels.map { CGFloat($0.size.rawValue) }.reduce(0, +)
        let isLandscape = UIScreen.main.bounds.height < UIScreen.main.bounds.width
        return isLandscape
            ? (
                {
                    ReadingPanelRelativeSize(
                        x: -CGFloat($0.rawValue) / total, y: -1.0, isLandscape: isLandscape)
                },
                { CGFloat($0.rawValue) * p.size.width / total },
                { _ in p.size.height },
                [GridItem(spacing: 0)],
                [.trailing]
            )
            : (
                {
                    ReadingPanelRelativeSize(
                        x: 1.0, y: CGFloat($0.rawValue) / total, isLandscape: isLandscape)
                },
                { _ in p.size.width },
                { _ in nil },
                panels.map {
                    GridItem(.fixed(CGFloat($0.size.rawValue) * p.size.height / total), spacing: 0)
                },
                [.bottom]
            )
    }

    private func closePanel(_ panel: ReadingPanel) {
        tryDo {
            guard let panels = panels else {
                return
            }
            let rep: any ReadingPanelsRepository = locate()
            try rep.delete(panel)
            self.panels!.remove(at: panels.firstIndex(of: panel)!)
            if focusedPanel == panel {
                focusedPanel = nil
            }
        }
    }

    private func closeExcept(_ panel: ReadingPanel) {
        tryDo {
            guard let panels = panels else {
                return
            }
            let rep: any ReadingPanelsRepository = locate()
            for p in panels {
                if p == panel {
                    continue
                }
                try rep.delete(p)
            }
            self.panels = [panel]
            if focusedPanel != nil && focusedPanel != panel {
                focusedPanel = nil
            }
        }
    }

    private func createPanel(_ after: ReadingPanel? = nil) {
        tryDo {
            guard let panels = panels else {
                return
            }
            if panels.count > Self.maxPanels {
                throw BusinessError(.createFailed)
            }
            let panelBookIds = Set(panels.map { $0.content }.filter { $0 != nil }.map { $0! })
            let rep: any ReadingBooksRepository = locate()
            let books = try rep.read$(by: .readingList, value: readingList.id)
            let bookId = books.first { !panelBookIds.contains($0.id) }?.id
            let pRep: any ReadingPanelsRepository = locate()
            let afterPanel = after ?? panels.last
            var (firstParts, secondParts): ([ReadingPanel], [ReadingPanel]) = {
                var fp: [ReadingPanel] = []
                var sp: [ReadingPanel] = []
                var inFirstParts = true
                for p in panels {
                    if inFirstParts {
                        fp.append(p)
                    } else {
                        sp.append(p)
                    }
                    if inFirstParts && p == afterPanel {
                        inFirstParts = false
                    }
                }
                return (fp, sp)
            }()
            let maxOrder = Int(afterPanel?.pOrder ?? 0)
            var nextOrder = 0
            if maxOrder >= Self.maxPanels {
                for (i, p) in firstParts.enumerated() {
                    p.pOrder = UInt8(i)
                    try pRep.update(p, bys: [.pOrder])
                }
                nextOrder = panels.count
            } else {
                nextOrder = maxOrder + 1
            }
            let panel = ReadingPanel()
                .with(\.id, UUID())
                .with(\.readingList, readingList.id)
                .with(\.type, .book)
                .with(\.content, bookId)
                .with(\.size, .normal)
                .with(\.pOrder, UInt8(nextOrder))
            try pRep.create(panel)
            for (i, p) in secondParts.enumerated() {
                p.pOrder = UInt8(nextOrder + i + 1)
                try pRep.update(p, bys: [.pOrder])
            }
            firstParts.append(panel)
            firstParts.append(contentsOf: secondParts)
            self.panels = firstParts
            focusedPanel = panel
        }
    }

    private func loadData() {
        tryDo {
            let pRep: any ReadingPanelsRepository = locate()
            panels = (try pRep.read$(by: .readingList, value: readingList.id, take: Self.maxPanels))
                .sorted { i, j in
                    i.pOrder >= j.pOrder
                }
            if panels!.count == 0 {
                createPanel()
            }
        }
    }

    private var closeMenuItem: ReadingPanelMenuItem {
        .button("Close List", "xmark") {
            onClose?()
        }
    }

    private func createPanelMenuItem(_ panel: ReadingPanel) -> ReadingPanelMenuItem {
        .button("New Panel", "rectangle.badge.plus") {
            createPanel(panel)
        }
    }

    private func closePanelMenuItem(_ panel: ReadingPanel) -> ReadingPanelMenuItem {
        .button("Close Panel", "rectangle.badge.minus") {
            closePanel(panel)
        }
    }

    private func closeOthersMenuItem(_ panel: ReadingPanel) -> ReadingPanelMenuItem {
        .button("Close Others", "rectangle.arrowtriangle.2.outward") {
            closeExcept(panel)
        }
    }
}

#Preview {
    OpenedReadingListView(ReadingList.mock())
        .setNotifyService().usePreviewServices().ignoresSafeArea()
}
