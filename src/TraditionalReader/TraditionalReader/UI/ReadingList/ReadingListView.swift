//
//  ReadingListView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/12.
//

import AppCommon
import SwiftUI
import WCDBSwift

struct ReadingListView: UpdatableViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    static let RECENTS_COUNT = 3
    static let imgProportion = 1026 / 582.0

    let readingList: ReadingList
    let onDelete: () -> Void
    let shadowCard: LiteralOnlyBool
    init(
        _ readingList: ReadingList,
        focusedTag: Binding<ReadingList?>,
        onDelete: @escaping () -> Void,
        shadowCard: LiteralOnlyBool = .false
    ) {
        self.readingList = readingList
        self.onDelete = onDelete
        self.shadowCard = shadowCard
        self._focusedTag = focusedTag
    }

    @State var opened = false
    @State var presentingBooks = false
    @Binding var focusedTag: ReadingList?
    @State var recentBooks: [ReadingBook] = []

    var forceUpdateBy: UUID? {
        readingList.id
    }

    var updateBys: [(any Equatable)?]? {
        [focusedTag, opened, recentBooks, presentingBooks]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        ZStack {
            if opened {
                OpenedReadingListView(readingList) {
                    opened = false
                    loadRecentBooks()
                }
            } else {
                Rectangle().fill(.transparent).aspectRatio(210 / 297, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 0) {
                            HStack(alignment: .center) {
                                Group {
                                    Image(systemName: "book").fixedSize()
                                    Text("Continue Reading")
                                }.onTapGesture {
                                    opened = true
                                }
                                Spacer()

                                PreventUpdate(recentBooks) {
                                    if recentBooks.isEmpty {

                                    } else {
                                        Menu("", systemImage: "clock") {
                                            ForEach(recentBooks, id: \.id) { book in
                                                Button(
                                                    action: {
                                                        tryDo {
                                                            let service: any ReadingService =
                                                                locate()
                                                            try service.readBook(book)
                                                            opened = true
                                                        }
                                                    },
                                                    label: {
                                                        HStack(spacing: 0) {
                                                            ReadingBookSummaryView(
                                                                book, inline: true)
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }

                            }.foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.leading, 15).padding(.vertical).padding(.trailing, 5)
                                .lightBorder(edges: [.bottom])
                                .background(.background)
                            ZStack {
                                Rectangle().fill(.black.opacity(0.3)).contentShape(Rectangle())
                                    .onTapGesture {
                                        presentingBooks = true
                                    }
                                ReadingListBooksView(
                                    readingList,
                                    hideTitleBar: true,
                                    readonly: true
                                ).allowsHitTesting(false)
                            }.fullScreenCover(isPresented: $presentingBooks) {
                                ReadingListBooksView(
                                    readingList,
                                    onSelect: { book in
                                        tryDo {
                                            let service: any ReadingService =
                                                locate()
                                            try service.readBook(book)
                                            presentingBooks = false
                                            opened = true
                                        }
                                    },
                                    onClose: {
                                        presentingBooks = false
                                    }
                                )
                            }
                            VStack(spacing: 0) {
                                HStack(alignment: .center, spacing: 5) {
                                    Text(readingList.name).font(.headline).fixedSize().padding(
                                        .trailing, 5
                                    ).foregroundStyle(.primary)

                                    Spacer()

                                    Menu("", systemImage: "ellipsis") {
                                        if readingList.id != .default {
                                            Button(
                                                role: .destructive,
                                                action: onDelete
                                            ) {
                                                Label(
                                                    "Delete ReadingList", systemImage: "trash"
                                                )
                                                .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding([.leading, .bottom, .top])
                                .padding(.trailing, 8)
                            }
                            .lightBorder(edges: [.top])
                            .background(.background)

                        }
                    }.background(.background)
                    .if(shadowCard) {
                        $0.clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(color: .black.opacity(0.1), radius: 5)
                    }
            }
        }
        .onAppear(perform: loadRecentBooks)
    }

    private func loadRecentBooks() {
        tryDo {
            let rep: any ReadingBooksRepository = locate()
            recentBooks = try rep.read$(
                by: .readingList, value: readingList.id, take: Self.RECENTS_COUNT,
                orderBy: .accessed,
                orderByDesc: true)
        }
    }
}

#Preview {
    ReadingListView(
        ReadingList.mock(), focusedTag: .constant(nil), onDelete: {},
        shadowCard: true
    ).padding([.top, .horizontal])
        .usePreviewServices()
}
