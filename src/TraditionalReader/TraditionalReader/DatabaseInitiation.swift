//
//  DatabaseInitiation.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/11.
//

import AppCommon
import Foundation
import SwiftUI
import WCDBSwift

func updateData(_ locator: ServicesLocator) throws {
    let initiazor = DatabaseInitiation(locator: locator)
    try initiazor.createDefaultBooklist()
}

private struct DatabaseInitiation: DelegatedServicesLocator {
    let locator: ServicesLocator

    func createDefaultBooklist() throws {
        let id = UUID.zero
        let rep: any ReadingListsRepository = locate()
        if try rep.checkExisted(by: .id, value: id) {
            return
        }
        let _ = LocalizedStringKey("Default Booklist")
        let booklist = ReadingList().with(\.id, id).with(
            \.name, Bundle.main.localizedString(forKey: "Default Booklist", value: nil, table: nil))
        try rep.create(booklist)
        try importDefaultBooks(id)
    }

    private func importDefaultBooks(_ readingListId: UUID) throws {
        let fm = FileManager.default
        let files = try fm.contentsOfDirectory(
            atPath: Bundle.main.path(forResource: "books", ofType: nil)!)
        var readingBookId: UUID? = nil
        for file in files {
            let url = Bundle.main.url(forResource: "books/\(file)", withExtension: nil)!
            let filesService: FilesService = locate()
            let file = try filesService.import(url: url, in: nil)
            let readingBooksRep: any ReadingBooksRepository = locate()
            let readingBook = ReadingBook().with(\.id, UUID()).with(\.book, file.id)
            try readingBooksRep.create(readingBook)
            readingBookId = readingBook.id
        }
        if readingBookId != nil {
            let readingPanel = ReadingPanel().with(\.id, UUID()).with(\.type, .book).with(
                \.content, readingBookId!
            ).with(\.readingList, readingListId)
            let readingPanelsRep: any ReadingPanelsRepository = locate()
            try readingPanelsRep.create(readingPanel)
        }
    }
}
