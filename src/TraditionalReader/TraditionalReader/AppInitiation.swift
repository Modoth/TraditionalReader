//
//  AppInitiation.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/20.
//

import AppCommon
import Foundation
import SwiftUI
import WCDBSwift

private func createTables(_ database: Database) throws {
    try database.createTable(File.self)
    try database.createTable(ReadingList.self)
    try database.createTable(ReadingPanel.self)
    try database.createTable(ReadingBook.self)

    try database.createTable(Dict.self)
    try database.createTable(DictFile.self)
    try database.createTable(DictSection.self)
    try database.createTable(DictItem.self)
}

private func registerServices(_ container: ServicesContainer) {
    // AppCommon
    container.register(factory: FileResourceManager$)
    container.register(factory: UUIDRepository$(File.default))
    container.register(factory: FilesService$)

    // Data
    container.register(factory: UUIDRepository$(ReadingList.default))
    container.register(factory: UUIDRepository$(ReadingBook.default))
    container.register(factory: UUIDRepository$(ReadingPanel.default))

    container.register(factory: UUIDRepository$(Dict.default))
    container.register(factory: UUIDRepository$(DictFile.default))
    container.register(factory: UUIDRepository$(DictSection.default))
    container.register(factory: UUIDRepository$(DictItem.default))

    // Services
    container.register(group: "mdx", factory: MdxDictParser$)
    container.register(group: "zim", factory: ZimDictParser$)

    // App
    container.register(factory: TxtMeasurer$)
    container.register(lifetime: .transient, factory: TxtPager$)

    container.register(factory: FontsService$)
    container.register(factory: DictsService$)
    container.register(lifetime: .transient, group: "mdx", factory: MdictModel$)
    container.register(lifetime: .transient, group: "zim", factory: ZdictModel$)

    container.register(factory: ReadingService$)
}

private func createDatabase(_ dbFileUrl: URL) -> Database {
    print(dbFileUrl)
    let database = Database(at: dbFileUrl)
    database.setConfig(
        named: "foreign_keys",
        withInvocation: { (handle: Handle) throws in
            try! handle.exec(StatementPragma().pragma(.foreignKeys).to(true))
        })
    database.add(tokenizer: BuiltinTokenizer.Verbatim)

    try! createTables(database)

    return database
}

func createLocator() -> ServicesLocator {
    let register = createServicesContainer()

    registerServices(register)
    let docDir = try! FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let dataDir = docDir.appending(path: ".data")
    register.register { createDatabase(dataDir.appendingPathComponent("data.db")) }
    register.register {
        FileResourceManagerConfig(root: dataDir.appendingPathComponent("files"))
    }
    let userSelectedAssetsUrl = getUserSelectedAssetsUrl()
    let _ = userSelectedAssetsUrl?.startAccessingSecurityScopedResource()
    register.register {
        FontsServiceConfig(
            builtinDir: Bundle.main.url(forResource: "fonts", withExtension: nil)!,
            userDir: docDir, userSelectedDir: userSelectedAssetsUrl)
    }
    register.register {
        DictsServiceConfig(
            builtinDir: Bundle.main.url(forResource: "dicts", withExtension: nil)!,
            userDir: docDir,
            userSelectedDir: userSelectedAssetsUrl,
            types: ["mdx", "zim"])
    }
    return register.build()
}

public var sharedLocator = createLocator()

extension View {
    public func useEnvironmentServices(_ services: ServicesLocator) -> some View {
        let fontsService: FontsService = services.locate()
        let dictsService: DictsService = services.locate()
        return
            self
            .environmentObject(fontsService)
            .environmentObject(dictsService)
            .task {
                let _ = await [
                    fontsService.load(),
                    dictsService.load(),
                ]
            }
    }
}
