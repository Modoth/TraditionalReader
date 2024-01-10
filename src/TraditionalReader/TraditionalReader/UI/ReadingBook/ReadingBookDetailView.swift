//
//  ReadingBookDetailView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/21.
//

import AppCommon
import Foundation
import SwiftUI

struct ReadingBookDetailView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }

    let readingBook: ReadingBook
    let isLandsapce: LiteralOnlyBool

    init(
        _ readingBook: ReadingBook,
        isLandsapce: LiteralOnlyBool = false
    ) {
        self.readingBook = readingBook
        self.isLandsapce = isLandsapce
    }

    @State var book: (file: File, parentList: ReadingList, url: URL)? = nil

    @State var openning: Bool = false

    var body: some View {
        let _ = Self._printTrace()
        Group {
            if openning, let parentList = book?.parentList {
                OpenedReadingListView(parentList) {
                    openning = false
                }
            }

            PreventUpdate(idBy: book?.file.id) {
                if let book = book {
                    VStack(spacing: 0) {
                        ScaledView(
                            scale: isLandsapce.value ? 0.6 : 0.8,
                            aspectRatio: (isLandsapce.value ? 2 : 1) * 210 / 297
                        ) {
                            FileReaderView(
                                name: book.file.name, url: book.url,
                                fileType: book.file.fileType,
                                position: Int(readingBook.position)
                            ).environmentOo(
                                ReadingPanelRelativeSize(x: 1, y: 1, isLandscape: isLandsapce.value)
                            )
                        }.overlay {
                            VStack {
                                Spacer()
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(book.parentList.name).layoutPriority(1)
                                        Spacer()
                                        if readingBook.comment != nil {
                                            Text(readingBook.comment!).foregroundStyle(.secondary)
                                        }
                                    }
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .padding([Edge.Set.vertical], 8)
                                    HStack(alignment: .bottom) {
                                        Text(book.file.name).font(.headline).lineLimit(1)
                                        Spacer()
                                    }
                                }.padding([Edge.Set.horizontal, .bottom])
                                    .background(.background)
                                    .if(isLandsapce) {
                                        $0.overlay {
                                            HStack {
                                                Spacer()
                                                Divider()
                                                Spacer()
                                            }
                                        }
                                    }
                                    .lighterBorder(edges: [.top, .bottom])
                            }.padding(.bottom, 8)
                        }
                    }
                    .onTapGesture {
                        tryDo {
                            let service: any ReadingService = locate()
                            try service.readBook(readingBook)
                            openning = true
                        }
                    }
                }
            }.onAppear(perform: loadData)
        }
    }

    private func loadData() {
        tryDo {
            let rep: any FilesRepository = locate()
            guard let bookFile = try rep.readOne(by: .id, value: readingBook.book) else {
                throw BusinessError(.fatalError)
            }
            let dRep: any ReadingListsRepository = locate()
            guard let parentList = try dRep.readOne(by: .id, value: readingBook.readingList) else {
                throw BusinessError(.fatalError)
            }
            let fm: any FileResourceManager = locate()
            let url = fm.url(id: bookFile.id, resource: "content")
            book = (bookFile, parentList, url)
        }
    }
}

#Preview {
    ComponentPreview {
        HStack {
            ReadingBookDetailView(ReadingBook.mock(), isLandsapce: false)
                .background(.white)
                .cornerRadius(10).lightShadow()
                .padding([.top, .horizontal]).background(.white)
            ReadingBookDetailView(ReadingBook.mock(), isLandsapce: false)
                .background(.white)
                .cornerRadius(10).lightShadow()
                .padding([.top, .horizontal]).background(.white)
        }
        ReadingBookDetailView(ReadingBook.mock(), isLandsapce: true)
            .background(.white).cornerRadius(10).lightShadow().padding([.top, .horizontal])
    }.usePreviewServices()
}
