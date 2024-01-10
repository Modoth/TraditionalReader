//
//  ReadingListBooksView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/20.
//

import AppCommon
import Foundation
import SwiftUI

struct ReadingListBooksView: UpdatableViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let onSelect: ((ReadingBook) -> Void)?
    let current: ReadingBook?
    let readingList: ReadingList
    let onClose: (() -> Void)?
    let hideTitleBar: Bool
    let width: Double
    let initListView: Bool
    let readonly: Bool
    @State var listView: Bool? = nil
    @State var highlightTag: ReadingBook?

    init(
        _ readingList: ReadingList, current: ReadingBook? = nil,
        width: Double = 150,
        hideTitleBar: Bool = false,
        initListView: Bool = false,
        readonly: Bool = false,
        onSelect: ((ReadingBook) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.readingList = readingList
        self.current = current
        self.onSelect = onSelect
        self.onClose = onClose
        self.hideTitleBar = hideTitleBar
        self.width = width
        self.readonly = readonly
        self.initListView = initListView
    }

    @State var books: [ReadingBook] = []
    @State var presentingOpenBookFromLibrary = false

    var updateBys: [(any Equatable)?]? {
        [books, presentingOpenBookFromLibrary, listView]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        let listView = self.listView ?? self.initListView
        VStack {
            if !hideTitleBar {
                HStack(alignment: .center, spacing: 0) {
                    if onClose != nil {
                        Button(
                            action: {
                                onClose!()
                            },
                            label: {
                                Image(systemName: "chevron.down").padding(8)
                            })
                    }
                    Spacer()
                    Text(readingList.name).font(.headline)
                    Spacer()
                    Menu(
                        content: {
                            Button("Open Library", systemImage: "building.columns") {
                                presentingOpenBookFromLibrary = true
                            }
                            Button("Import File", systemImage: "doc.badge.plus") {
                                presentingOpenBookFromLibrary = true
                            }
                        },
                        label: {
                            Image(systemName: "plus").padding(8)
                        })
                    Button(
                        action: {
                            self.listView = !listView
                        },
                        label: {
                            Image(systemName: listView ? "books.vertical" : "list.bullet").padding(
                                8)
                        })
                }.padding([.horizontal])
                    .padding(.top, 14)
                    .padding(.bottom, 8).background(.background)
                    .sheet(isPresented: $presentingOpenBookFromLibrary) {
                        LibraryView(initPath: "") { book in
                            openBook(book)
                            presentingOpenBookFromLibrary = false
                        }
                    }
            }

            if listView {
                List {
                    if !books.isEmpty {
                        ForEach(books, id: \.id) { book in
                            HStack {
                                ReadingBookSummaryView(book)
                                Spacer()
                            }
                            .listRowInsets(EdgeInsets())
                            .onTapGesture {
                                onSelect?(book)
                            }
                        }.onDelete { (indexSet) in
                            for i in indexSet {
                                closeBook(books[i])
                            }
                            books.remove(atOffsets: indexSet)
                        }.listRowBackground(Color.black.opacity(0))
                    } else {
                        HStack {
                            Text("You don't have any books here").font(.footnote.italic())
                        }.listRowBackground(Color.black.opacity(0)).listRowInsets(EdgeInsets())
                    }
                }.listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal)
            } else {
                HStack {
                    if !books.isEmpty {
                        let aspectRatio = 210 / 297.0
                        let maxZ = UInt32.max
                        let height = width / aspectRatio
                        var zMax = books.map { $0.layoutZ }.max()!
                        let getNextZ: (UInt32) -> UInt32 = { z in
                            if z == zMax && z != 0 {
                                return z
                            }
                            zMax += 1
                            if zMax > maxZ {
                                let books = books.sorted { $0.layoutZ <= $1.layoutZ }
                                let rep: any ReadingBooksRepository = locate()
                                for (i, book) in books.enumerated() {
                                    book.layoutZ = UInt32(i)
                                    try? rep.update(book, bys: [.layoutZ])
                                }
                                DispatchQueue.main.async {
                                    self.books = books
                                }
                                zMax = UInt32(books.count)
                            }
                            return zMax
                        }

                        GeometryReader { proxy in
                            let getOffset: (width: (Double) -> Double, height: (Double) -> Double) =
                                readonly
                                ? {
                                    let minX = books.map { $0.layoutX.d$ }.min()!
                                    let maxX = books.map { $0.layoutX.d$ }.max()!
                                    let minY = books.map { $0.layoutY.d$ }.min()!
                                    let maxY = books.map { $0.layoutY.d$ }.max()!
                                    let fWidth: (Double) -> Double =
                                        maxX == minX
                                        ? { _ in proxy.size.width / 2 - width / 2 }
                                        : { x in
                                            (proxy.size.width) / (maxX - minX) * (x.d$ - minX)
                                                - width / 2
                                        }
                                    let fHeight: (Double) -> Double =
                                        maxY == minY
                                        ? { _ in proxy.size.height / 2 - height / 2 }
                                        : { y in
                                            (proxy.size.height) / (maxY - minY) * (y.d$ - minY)
                                                - height / 2
                                        }
                                    return (fWidth, fHeight)
                                }()
                                : (
                                    { ($0.d$ + 1) / 2 * (proxy.size.width - width) },
                                    {
                                        ($0.d$ + 1) / 2 * (proxy.size.height - height)
                                    }
                                )
                            ZStack {
                                ForEach(books, id: \.id) { book in
                                    DragableReadingBook(
                                        readingBook: book,
                                        highlightTag: $highlightTag,
                                        readonly: readonly,
                                        width: width,
                                        aspectRatio: aspectRatio,
                                        size: proxy.size,
                                        getOffset: getOffset,
                                        getNextZ: getNextZ
                                    ) {
                                        onSelect?(book)
                                    }
                                }
                            }
                        }.padding(.vertical, readonly ? height / 2 : 0)
                            .padding(.horizontal, readonly ? width / 2 : 0)
                            .padding(10)
                    }
                }.clipped()
            }
        }
        .onAppear(perform: loadData)
        .background(listView ? .white : .transparent)
    }

    private func loadData() {
        tryDo {
            let rep: any ReadingBooksRepository = locate()
            let books = try rep.read$(by: .readingList, value: readingList.id, orderBy: .layoutZ)
            self.books = books.sorted { $0.layoutY > $1.layoutY }
        }
    }

    private func openBook(_ book: File) {
        tryDo {
            let openedBook = ReadingBook()
                .with(\.id, UUID())
                .with(\.book, book.id)
                .with(\.readingList, readingList.id)
            let rep: any ReadingBooksRepository = locate()
            try rep.create(openedBook)
            books.insert(openedBook, at: 0)
        }
    }

    private func closeBook(_ book: ReadingBook) {
        tryDo {
            let rep: any ReadingBooksRepository = locate()
            try rep.delete(by: .id, value: book.id)
            books.remove(at: books.firstIndex(of: book)!)
        }
    }
}

struct DragableReadingBook: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let readingBook: ReadingBook
    @Binding var highlightTag: ReadingBook?
    let readonly: Bool
    let width: Double
    let aspectRatio: Double
    let size: CGSize
    let getOffset: (width: (Double) -> Double, height: (Double) -> Double)
    let getNextZ: (UInt32) -> UInt32
    let onSelect: () -> Void
    @State var changedTag: UUID = UUID()
    @GestureState var fingerLocation: CGPoint? = nil
    var body: some View {
        let _ = changedTag
        let height = width / aspectRatio
        PreventUpdate(readingBook.id) {
            ScaledView(scale: 0.7, aspectRatio: aspectRatio) {
                ReadingBookDetailView(readingBook).background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .frame(width: width, height: height)
        }
        .shadow(color: .black.opacity(highlightTag == readingBook ? 0.3 : 0.1), radius: 5)
        .onTapGesture {
            if highlightTag == readingBook {
                onSelect()
                return
            }
            let z = getNextZ(readingBook.layoutZ)
            let needSave = z > readingBook.layoutZ
            readingBook.layoutZ = z
            if needSave {
                tryDo {
                    let rep: any ReadingBooksRepository = locate()
                    try rep.update(readingBook, bys: [.layoutZ])
                }
            }
            DispatchQueue.main.async {
                highlightTag = readingBook
            }
        }
        .gesture(
            DragGesture().updating($fingerLocation) { (value, _, _) in
                updateLayout(value.location, value.startLocation)
            }.onEnded { value in
                updateLayout(value.location, value.startLocation, true)
            }
        )
        .rotationEffect(.degrees(readingBook.layoutAngle), anchor: .center)
        .offset(
            x: getOffset.width(readingBook.layoutX),
            y: getOffset.height(readingBook.layoutY)
        ).zIndex(Double(readingBook.layoutZ))
    }

    private func updateLayout(_ loc: CGPoint, _ sloc: CGPoint, _ save: Bool = false) {
        if readonly {
            return
        }
        readingBook.layoutX = max(
            min(readingBook.layoutX + (loc.x - sloc.x) / (size.width - width) / 2.0, 1), -1)
        readingBook.layoutY = max(
            min(
                readingBook.layoutY + (loc.y - sloc.y) / (size.height - width / aspectRatio) / 2.0,
                1),
            -1)
        readingBook.layoutZ = getNextZ(readingBook.layoutZ)
        if save {
            tryDo {
                let rep: any ReadingBooksRepository = locate()
                try rep.update(readingBook, bys: [.layoutX, .layoutY])
            }
        }
        DispatchQueue.main.async {
            changedTag = UUID()
        }
    }
}
