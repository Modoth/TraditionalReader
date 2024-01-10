//
//  IdFileManagerTests.swift
//  AppCommonTests
//
//  Created by zxq on 2023/9/20.
//

import XCTest

@testable import AppCommon

final class IdFileManagerTests: TestCaseBase {

    override func setUpWithError() throws {
        register.register { FileResourceManagerConfig(root: self.tmpDataUrl) }
        register.register(factory: FileResourceManager$)
    }

    override func tearDownWithError() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: tmpDataUrl.path()) {
            try fm.removeItem(at: tmpDataUrl)
        }
    }

    func test_fileUrl() throws {
        let uuid = UUID(uuidString: "EC0EB3DA-3BC3-41EE-9368-7E787615E448")!
        let fm: FileResourceManager = locator.locate()
        let url = fm.url(id: uuid, resource: nil)
        XCTAssertEqual(
            url.absoluteString, tmpDataUrl.absoluteString + "/EC/0E/B3/DA/3BC341EE93687E787615E448")
    }

    func test_copy_and_delete() throws {
        let path = Bundle(for: Self.self).url(forResource: "data/test.txt", withExtension: nil)
        let fm: any FileResourceManager = locator.locate()
        let fid = UUID()
        let resourceName = "content"
        try fm.copy(fromUrl: path!, toId: fid, resource: resourceName)
        let toPath = fm.url(id: fid, resource: resourceName).path()
        XCTAssertTrue(FileManager.default.fileExists(atPath: toPath))
        try fm.delete(id: fid, resource: nil)
        XCTAssertTrue(!FileManager.default.fileExists(atPath: toPath))
    }
}
