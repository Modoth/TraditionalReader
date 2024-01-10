//
//  DictParserTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/11/18.
//

import XCTest

@testable import AppCommon
@testable import TraditionalReader

final class DictParserTests: XCTestCase {

    func testExample() throws {
        let mdx = Bundle(for: DictsServiceImpl.self).url(
            forResource: "dicts/康熙字典.mdx", withExtension: nil)!
        let mdd = Bundle(for: DictsServiceImpl.self).url(
            forResource: "dicts/康熙字典.mdd", withExtension: nil)!
        let parser = MdxDictParser()
        let dict = try parser.parse(file: mdx, resources: [])
        print(dict.items["阿"]?.value)
    }
}
