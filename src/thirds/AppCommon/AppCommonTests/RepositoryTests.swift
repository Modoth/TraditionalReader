//
//  RepositoryTests.swift
//  AppCommonTests
//
//  Created by zxq on 2023/9/20.
//

import WCDBSwift
import XCTest

@testable import AppCommon

final class RepositoryTests: TestCaseBase {
    //    func test<each TB, each TV>(bys: repeat each TB, values: repeat each TV) -> (repeat(each TB, each TV)) where repeat each TB: View {
    //        return (repeat(each bys, each values))
    //    }
    override func setUpWithError() throws {
        register.register(factory: {
            {
                let fm = FileManager.default
                let dbUrl = self.tmpDataUrl.appendingPathComponent("\(RepositoryTests.self).db")
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
                return database
            }
        })
        register.register(factory: UUIDRepository$(File.default))

    }

    override func tearDownWithError() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: tmpDataUrl.path()) {
            try fm.removeItem(at: tmpDataUrl)
        }
    }
    func text_bys() throws {
        let testName = "file name"
        let testPath = "/file/path"
        let database: Database = locate()
        try database.insert(
            File.mock().with(\.name, testName),
            File.mock().with(\.name, testName).with(\.path, testPath), File.mock(), File.mock(),
            intoTable: File.TableName)
        let rep: any FilesRepository = locate()
    }
}
