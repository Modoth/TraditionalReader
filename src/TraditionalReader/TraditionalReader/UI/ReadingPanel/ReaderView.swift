//
//  ReaderView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/19.
//

import AppCommon
import SwiftUI

protocol ReaderView: View {
    init(
        _ readingList: ReadingList, _ panel: ReadingPanel,
        presentingMenu: Binding<Bool>
    )
}

struct ReadingPanelRelativeSize: Equatable {
    let x: CGFloat
    let y: CGFloat
    let isLandscape: Bool?
    static let zero = ReadingPanelRelativeSize(x: 0, y: 0, isLandscape: nil)
    var identity: Bool {
        return abs(x) == 1 && abs(y) == 1
    }
}

extension ReadingPanelType {
    var view: any ReaderView.Type {
        switch self {
        case .book:
            BookReaderView.self
        case .web:
            WebReaderView.self
        case .dictionary:
            DictionaryReaderView.self
        }
    }
}

struct WebReaderView: ReaderView {
    @State var t: Bool = false
    init(
        _ readingList: ReadingList, _ panel: ReadingPanel,
        presentingMenu: Binding<Bool>
    ) {

    }

    var body: some View {
        let _ = Self._printTrace()
        Text(t ? "web" : "pem").onTapGesture {
            t.toggle()
        }.onAppear {
            Self._printTrace()
        }
    }
}

struct DictionaryReaderView: ReaderView {
    init(
        _ readingList: ReadingList, _ panel: ReadingPanel,
        presentingMenu: Binding<Bool>
    ) {

    }

    var body: some View {
        let _ = Self._printTrace()
        Text("dictionary")
    }
}
