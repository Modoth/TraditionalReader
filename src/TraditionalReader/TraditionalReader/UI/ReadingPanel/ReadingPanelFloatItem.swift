//
//  ReadingPanelFloatItem.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/11.
//

import Foundation
import SwiftUI

class ReadingPanelFloatItem: Identifiable, Equatable {
    static func == (lhs: ReadingPanelFloatItem, rhs: ReadingPanelFloatItem) -> Bool {
        lhs.id == rhs.id
    }

    init(alignment: Edge, body: @escaping () -> AnyView) {
        self.alignment = alignment
        self.body = body
    }

    let alignment: Edge
    let body: () -> AnyView
}

struct ReadingPanelFloatItemKey: PreferenceKey {
    static let defaultValue: [ReadingPanelFloatItem] = []
    static func reduce(
        value: inout [ReadingPanelFloatItem], nextValue: () -> [ReadingPanelFloatItem]
    ) {
        value.append(contentsOf: nextValue())
    }
}
