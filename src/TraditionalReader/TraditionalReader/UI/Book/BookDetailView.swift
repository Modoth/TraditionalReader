//
//  BookDetailView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/23.
//

import AppCommon
import Foundation
import SwiftUI

struct BookDetailView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    let book: File
    @State var desk: ReadingList? = nil
    @State var openedBooks: [(ReadingBook, ReadingList)] = []
    init(_ book: File) {
        self.book = book
    }

    var body: some View {
        let _ = Self._printTrace()
        HStack {
            if desk != nil {
                OpenedReadingListView(desk!) {
                    desk = nil
                }
            } else {
                HStack {
                    Image(book.fileIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped().frame(width: 40, height: 40)
                    Text(book.name)
                    Spacer()
                    if openedBooks.count > 0 {
                        HStack {
                            ForEach(openedBooks, id: \.0.id) { (opened, desk) in
                                Text(desk.name).lineLimit(1).onTapGesture {
                                    tryDo {
                                        let service: ReadingService = locate()
                                        try service.readBook(opened)
                                        self.desk = desk
                                    }
                                }.font(.caption)
                            }
                        }
                    }
                }.onTapGesture {
                    if openedBooks.count == 1 {
                        tryDo {
                            let service: ReadingService = locate()
                            try service.readBook(openedBooks[0].0)
                            self.desk = openedBooks[0].1
                        }
                    } else {
                        openBook(book)
                    }
                }
            }
        }
        .onAppear(perform: loadData)
    }

    private func openBook(_ book: File) {
        tryDo {
            let openedBook = ReadingBook().with(\.id, UUID())
                .with(\.readingList, UUID.zero)
                .with(\.book, book.id)
            let rep: any ReadingBooksRepository = locate()
            try rep.create(openedBook)
            let service: ReadingService = locate()
            try service.readBook(openedBook)
            let dRep: any ReadingListsRepository = locate()
            desk = try dRep.readOne(by: .id, value: UUID.zero)
        }
    }

    private func loadData() {
        tryDo {
            let openedRep: any ReadingBooksRepository = locate()
            let dRep: any ReadingListsRepository = locate()
            let openeds = try openedRep.read$(by: .book, value: book.id)
            var openedBooks: [(ReadingBook, ReadingList)] = []
            for o in openeds {
                let desk = try dRep.readOne(by: .id, value: o.readingList)!
                openedBooks.append((o, desk))
            }
            self.openedBooks = openedBooks
        }
    }
}

#Preview {
    BookDetailView(File.default).usePreviewServices()
}
