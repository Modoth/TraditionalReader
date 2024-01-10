//
//  BookReaderView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/19.
//

import AppCommon
import SwiftUI

struct BookReaderView: UpdatableViewBase, ReaderView {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var relativeSize: OO<ReadingPanelRelativeSize>

    let readingList: ReadingList
    let readingPanel: ReadingPanel

    init(
        _ readingList: ReadingList, _ readingPanel: ReadingPanel,
        presentingMenu: Binding<Bool>
    ) {
        self.readingList = readingList
        self.readingPanel = readingPanel
        self._presentingMenu = presentingMenu
    }

    @State var book: (readingBook: ReadingBook, file: File, fileUrl: URL)? = nil
    @State var presentingSelectBook = false
    @Binding var presentingMenu: Bool

    var updateBys: [(any Equatable)?]? {
        [book?.0.id, presentingSelectBook, presentingMenu]
    }

    var forceUpdateBy: UUID? {
        readingPanel.content
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        ZStack {
            PreventUpdate(idBy: book?.0.id) {
                if let book = book {
                    FileReaderView(
                        name: book.file.name, url: book.fileUrl, fileType: book.file.fileType,
                        position: Int(book.readingBook.position),
                        onClick: {
                            presentingMenu.toggle()
                        },
                        onPositionChanged: updatePosition
                    )
                }
            }

            PreventUpdate(presentingSelectBook) {
                if presentingSelectBook {
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial).clipShape(Rectangle()).onTapGesture {
                            presentingSelectBook = false
                        }
                        VStack {
                            ReadingListBooksView(
                                readingList, current: book?.0,
                                width: relativeSize.value.identity ? 150 : 120
                            ) { b in
                                tryDo {
                                    let rep: any ReadingPanelsRepository = locate()
                                    readingPanel.content = b.id
                                    try rep.update(readingPanel, bys: [.content])
                                    try openBook(b)
                                    presentingSelectBook = false
                                    presentingMenu = false
                                }
                            } onClose: {
                                presentingSelectBook = false
                                presentingMenu = false
                            }
                        }
                    }
                }
            }
        }.preference(
            key: ReadingPanelMenuItemsKey.self,
            value: [
                ReadingPanelMenuItem(id: "\(\Self.presentingSelectBook)") {
                    AnyView(
                        Button("", systemImage: "books.vertical") {
                            presentingMenu = false
                            presentingSelectBook = true
                        })
                }
            ]
        )
        .onAppear(perform: loadData)
    }

    private func updatePosition(_ pos: Int) {
        tryDo {
            let rep: any ReadingBooksRepository = locate()
            let readingBook = book!.0
            readingBook.position = UInt32(pos)
            readingBook.accessed = Date()
            try rep.update(readingBook, bys: [.accessed, .position])
        }
    }

    private func loadData() {
        tryDo {
            guard let openedBookId = readingPanel.content else {
                presentingSelectBook = true
                return
            }

            let rep: any ReadingBooksRepository = locate()
            guard let openedBook = try rep.readOne(by: .id, value: openedBookId) else {
                presentingSelectBook = true
                return
            }
            try openBook(openedBook)
        }
    }

    private func openBook(_ readingBook: ReadingBook) throws {
        let fRep: any FilesRepository = locate()
        let file = try fRep.readOne(by: .id, value: readingBook.book)!
        let fm: FileResourceManager = locate()
        let url = fm.url(id: file.id, resource: "content")
        book = (readingBook, file, url)
    }
}

#Preview {
    BookReaderView(
        ReadingList.mock(), ReadingPanel.mock().with(\.type, .book).with(\.content, UUID.default),
        presentingMenu: .constant(true)
    ).usePreviewServices()
}
