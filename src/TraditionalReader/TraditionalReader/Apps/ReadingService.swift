//
//  ReadingService.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/22.
//

import AppCommon
import Foundation

protocol ReadingService {
    func readBook(_ book: ReadingBook) throws
}

let ReadingService$ = { ReadingServiceImpl() as any ReadingService }

private class ReadingServiceImpl: ReadingService, Service {
    func readBook(_ book: ReadingBook) throws {
        let rep: any ReadingPanelsRepository = locate()
        let panels = try rep.read$(by: .readingList, value: book.readingList)
        let existedPanel = panels.first { $0.id == book.id } != nil
        if existedPanel {
            return
        }
        try rep.delete(by: .readingList, value: book.readingList)
        let panel = ReadingPanel()
            .with(\.id, UUID())
            .with(\.readingList, book.readingList)
            .with(\.type, .book)
            .with(\.content, book.id)
        try rep.create(panel)
    }
}
