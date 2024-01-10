//
//  RecentAddingBooksView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/22.
//

import AppCommon
import Foundation
import SwiftUI

struct RecentAddingBooksView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let fullscreen: LiteralOnlyBool
    let maxCount: Int?
    let onSelect: ((File) -> Void)?
    init(
        fullscreen: LiteralOnlyBool = false, maxCount: Int? = nil, onSelect: ((File) -> Void)? = nil
    ) {
        self.fullscreen = fullscreen
        self.maxCount = maxCount
        self.onSelect = onSelect
    }

    @State var books: [File] = []

    var body: some View {
        let _ = Self._printTrace()
        Group {
            if fullscreen.value {
                List {
                    ForEach(books) { book in
                        BookSummaryView(book).padding(.vertical, 5)
                    }
                }.padding(.top)
                    .listStyle(.plain)
            } else {
                VStack(spacing: 0) {
                    ForEach(books) { book in
                        BookSummaryView(book).padding(.vertical, 12).lineLimit(1)
                            .padding(.vertical, 2)
                            .border(
                                .black.opacity(0.1), width: 1,
                                edges: book == books.last ? [] : [.bottom])
                    }.padding(.horizontal)
                }.padding(.bottom)
            }
        }
        .onAppear(perform: loadData)
    }

    private func loadData() {
        tryDo {
            let rep: any FilesRepository = locate()
            books = try rep.read$(
                by: .type, value: NodeType.leaf, take: maxCount, orderBy: .accessed,
                orderByDesc: true)
        }
    }
}

#Preview {
    RecentAddingBooksView(fullscreen: true)
        .usePreviewServices()
}
