//
//  RecentReadingView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/21.
//

import AppCommon
import Foundation
import SwiftUI

struct RecentReadingView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let fullscreen: LiteralOnlyBool
    let maxCount: LiteralOnlyInt?

    init(fullscreen: LiteralOnlyBool = false, maxCount: LiteralOnlyInt? = nil) {
        self.fullscreen = fullscreen
        self.maxCount = maxCount
    }

    @State var books: [ReadingBook]? = nil

    var body: some View {
        let _ = Self._printTrace()
        Group {
            if let books = self.books {
                if fullscreen%! {
                    ScrollView {
                        LazyVGrid(
                            columns: (0..<1).map { _ in
                                GridItem(spacing: 0)
                            }, spacing: 0
                        ) {
                            ForEach(books, id: \.id) { book in
                                ReadingBookDetailView(book, isLandsapce: true)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .lightShadow()
                                    .padding(8)
                            }
                        }
                    }.padding(.horizontal, 8)
                } else {
                    CarouselV(books, id: \.id, scale: 0.6) { book in
                        ReadingBookDetailView(book)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .lightShadow()
                    }
                }
            } else {
                HStack {}.onAppear(perform: loadRecentBooks)
            }
        }
    }

    private func loadRecentBooks() {
        tryDo {
            let rep: any ReadingBooksRepository = locate()
            books = try rep.read$(take: maxCount%?, orderBy: .accessed, orderByDesc: true)
        }
    }
}

#Preview {
    RecentReadingView(fullscreen: true).padding([.top, .horizontal])
        .usePreviewServices()
}
