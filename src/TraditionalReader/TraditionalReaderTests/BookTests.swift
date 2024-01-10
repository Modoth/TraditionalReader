//
//  BookTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/9/19.
//

import AppCommon
import WCDBSwift
import XCTest

@testable import TraditionalReader

final class BookTests: TestCaseBase {

    func test_createTable() throws {
        let fm = FileManager.default
        let dbUrl = tmpDataUrl.appendingPathComponent("\(#function).db")
        print(dbUrl)
        if fm.fileExists(atPath: dbUrl.path()) {
            try fm.removeItem(at: dbUrl)
        }
        let database = Database(at: dbUrl)

        database.setConfig(
            named: "foreign_keys",
            withInvocation: { (handle: Handle) throws in
                try! handle.exec(StatementPragma().pragma(.foreignKeys).to(true))
            })
        database.add(tokenizer: BuiltinTokenizer.Verbatim)
        try database.createTable(File.self)

        let pFolder = File()
        pFolder.id = UUID()
        pFolder.name = "parent folder"
        pFolder.path = pFolder.name
        pFolder.type = .branch

        let folder1 = File()
        folder1.id = UUID()
        folder1.name = "folder 1"
        folder1.parent = pFolder.id
        folder1.path = pFolder.path + "/" + folder1.name
        folder1.type = .branch

        let book2 = File()
        book2.id = UUID()
        book2.name = "book 2"
        book2.parent = pFolder.id
        book2.path = pFolder.path + "/" + book2.name
        book2.type = .leaf

        let cBook1 = File()
        cBook1.id = UUID()
        cBook1.name = "child book 1"
        cBook1.parent = folder1.id
        cBook1.path = folder1.path + "/" + cBook1.name
        cBook1.type = .leaf

        try database.insert(pFolder, folder1, book2, cBook1, intoTable: File.TableName)
        var files: [File] = try database.getObjects(fromTable: File.TableName)
        XCTAssert(files.count == 4)

        //        cBook1.id = UUID()
        //        XCTAssertThrowsError(try database.insert(cBook1, intoTable: File.TableName))

        try database.delete(
            fromTable: File.TableName, where: File.Properties.id == folder1.id.uuidString)
        files = try database.getObjects(fromTable: File.TableName)
        XCTAssert(files.count == 3)
    }
}
