//
//  ReadingListsView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/19.
//

import AppCommon
import SwiftUI
import WCDBSwift

struct ReadingListsView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let fullscreen: LiteralOnlyBool
    let maxCount: LiteralOnlyInt?
    init(fullscreen: LiteralOnlyBool = false, maxCount: LiteralOnlyInt? = nil) {
        self.fullscreen = fullscreen
        self.maxCount = maxCount
    }

    @State var readingLists: [ReadingList] = []
    @State var focusedList: ReadingList? = nil
    @State var presentingCreateList = false
    @State var newListName = ""

    var body: some View {
        let _ = Self._printTrace()
        if fullscreen%! {
            PreventUpdate(readingLists) {
                ScrollView {
                    ForEach(readingLists, id: \.id) { list in
                        ReadingListView(
                            list, focusedTag: $focusedList, onDelete: { deleteReadingList(list) },
                            shadowCard: true
                        ).padding([
                            .horizontal, .bottom,
                        ])
                    }
                }
            }.alert("New ReadingList", isPresented: $presentingCreateList) {
                TextField("ReadingList Name", text: $newListName)
                Button("Cancle") {
                    newListName = ""
                }
                Button("OK") {
                    createReadingList()
                }
            }.toolbar {
                Button("New ReadingList", systemImage: "plus") {
                    presentingCreateList = true
                }
            }
            .onAppear(perform: loadData)
        } else {
            CarouselV(readingLists, id: \.id) { list in
                ReadingListView(
                    list, focusedTag: $focusedList, onDelete: { deleteReadingList(list) },
                    shadowCard: true
                )
            }.onAppear(perform: loadData)
        }
    }

    private func loadData() {
        tryDo {
            let rep: any ReadingListsRepository = locate()
            readingLists = try rep.read$(take: maxCount%?)
        }
    }

    private func createReadingList() {
        let name = newListName
        newListName = ""
        if name == "" {
            return
        }
        tryDo {
            let newList = ReadingList().with(\.id, UUID()).with(\.name, name)
            let rep: any ReadingListsRepository = locate()
            try rep.create(newList)
            readingLists.append(newList)
            focusedList = newList
        }
    }

    private func deleteReadingList(_ list: ReadingList) {
        tryDo {
            let rep: any ReadingListsRepository = locate()
            try rep.delete(by: .id, value: list.id)
            readingLists.remove(at: readingLists.firstIndex(of: list)!)
        }
    }
}

#Preview {
    ComponentPreview {
        NavigationStack {
            ReadingListsView(fullscreen: true)
        }
    }.usePreviewServices()
}
