//
//  ReadingPanelMenuItem.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/24.
//

import Foundation
import SwiftUI

struct ReadingPanelMenuItem: Equatable {
    static func == (lhs: ReadingPanelMenuItem, rhs: ReadingPanelMenuItem) -> Bool {
        lhs.id == rhs.id
    }

    let id: String
    let body: () -> AnyView
}

extension ReadingPanelMenuItem {
    static func button(_ id: String, _ icon: String, action: @escaping () -> Void)
        -> Self
    {
        Self(id: id) {
            AnyView(
                Button("", systemImage: icon, action: action)
            )
        }
    }
}

struct ReadingPanelMenuItemsKey: PreferenceKey {
    static let defaultValue: [ReadingPanelMenuItem] = []
    static func reduce(value: inout [ReadingPanelMenuItem], nextValue: () -> [ReadingPanelMenuItem])
    {
        value.append(contentsOf: nextValue())
    }
}
