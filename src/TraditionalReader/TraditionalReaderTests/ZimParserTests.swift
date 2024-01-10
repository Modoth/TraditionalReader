//
//  ZimParserTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/11/19.
//

import XCTest

@testable import AppCommon
@testable import TraditionalReader

final class ZimParserTests: XCTestCase {
    func testExample() throws {
        let zim = Bundle(for: DictsServiceImpl.self).url(
            forResource: "dicts/archlinux.zim", withExtension: nil)!
        let parser = ZimDictParser()
        let dict = try parser.parse(file: zim)
        print(dict.items["Windows and Arch Dual Boot"]?.value)
    }
}
