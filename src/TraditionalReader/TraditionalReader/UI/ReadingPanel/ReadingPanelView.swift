//
//  ReadingPanelView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/26.
//

import AppCommon
import Foundation
import SwiftUI

struct ReadingPanelView: UpdatableView {
    let list: ReadingList
    let panel: ReadingPanel
    let menu: [ReadingPanelMenuItem]

    init(
        _ readingList: ReadingList, _ panel: ReadingPanel,
        menu: [ReadingPanelMenuItem] = [],
        focusedTag: Binding<ReadingPanel?> = .constant(nil)
    ) {
        self.list = readingList
        self.panel = panel
        self.menu = menu
        _focusedTag = focusedTag
        _presentingMenus = .init(initialValue: panel == focusedTag.wrappedValue)
    }

    @State var additionalMenu: [ReadingPanelMenuItem] = []
    @State var floatingMenu: [ReadingPanelFloatItem] = []
    @State var presentingMenus: Bool
    @Binding var focusedTag: ReadingPanel?

    var updateBys: [(any Equatable)?]? {
        [
            panel.id, list.id,
            presentingMenus,
            menu, additionalMenu, floatingMenu,
            focusedTag,
        ]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        ZStack {
            PreventUpdate(panel.id, list.id) {
                Rectangle().fill(.transparent).contentShape(Rectangle())
                    .onTapGesture {
                        presentingMenus.toggle()
                    }
                AnyView(
                    panel.type.view.init(
                        list, panel,
                        presentingMenu: $presentingMenus
                    )
                )
            }
            PreventUpdate(presentingMenus, menu, additionalMenu, floatingMenu) {
                if presentingMenus {
                    VStack {
                        HStack(spacing: 0) {
                            ForEach(menu, id: \.id) { item in
                                item.body()
                                if item != menu.last {
                                    Spacer()
                                }
                            }
                            ForEach(additionalMenu, id: \.id) { item in
                                if item != menu.first {
                                    Spacer()
                                }
                                item.body()
                            }
                        }.padding(.horizontal).padding(.vertical, 15)
                            .background(
                                .background.shadow(
                                    .drop(
                                        color: Color(
                                            cgColor: .init(red: 0, green: 0, blue: 0, alpha: 0.1)),
                                        radius: 1, y: 0)))
                        Spacer()
                        VStack {
                            ForEach(floatingMenu) { item in
                                if item.alignment == .bottom {
                                    item.body().padding(.vertical, 5).contentShape(Rectangle())
                                }
                            }
                        }.padding()
                            .background(
                                .background.shadow(
                                    .drop(
                                        color: Color(
                                            cgColor: .init(red: 0, green: 0, blue: 0, alpha: 0.1)),
                                        radius: 1, y: 0)))
                    }
                }
            }
        }.onPropertyChange(of: focusedTag) { new in
            if presentingMenus && panel != new {
                presentingMenus = false
            }
        }.onPropertyChange(of: presentingMenus) { new in
            if new {
                focusedTag = panel
            } else {
                if focusedTag == panel {
                    focusedTag = nil
                }
            }
        }.onPreferenceChange(
            ReadingPanelMenuItemsKey.self,
            perform: { value in
                additionalMenu = value
            }
        ).onPreferenceChange(
            ReadingPanelFloatItemKey.self,
            perform: { value in
                floatingMenu = value
            }
        )
    }
}

#Preview {
    ReadingPanelView(
        ReadingList.mock(), ReadingPanel.mock().with(\.type, .book),
        menu: [
            ReadingPanelMenuItem(id: "Close List") {
                AnyView(
                    Button("", systemImage: "xmark.circle") {

                    })
            },
            ReadingPanelMenuItem(id: "New Panel") {
                AnyView(
                    Button("", systemImage: "plus") {

                    })
            },
            ReadingPanelMenuItem(id: "Close Panel") {
                AnyView(
                    Button("", systemImage: "xmark") {

                    })
            },
        ]
    ).usePreviewServices()
}
