//
//  MockRepositoryTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/10/21.
//

import XCTest

@testable import AppCommon
@testable import TraditionalReader

final class MockRepositoryTests: XCTestCase {
    func test_mockEntities() throws {
        var m: Any? = nil
        let types: [Any] = [ReadingBook.self, ReadingList.self, ReadingPanel.self]
        for t in types {
            let decodeT = t as! any Codable.Type
            m = try decodeT.init(from: MockDecoder())
            XCTAssertNotNil(m)
        }
    }
}
