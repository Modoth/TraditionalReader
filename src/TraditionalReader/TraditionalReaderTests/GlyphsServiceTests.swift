//
//  GlyphsServiceTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/9/27.
//

import XCTest

@testable import TraditionalReader

final class GlyphsServiceTests: XCTestCase {

    func test_t() throws {
        let s = GlyphsService()
        let a = Array("我")[0]
        let scalars = a.unicodeScalars
        let c = scalars[scalars.startIndex].value
        let g = s.get("我", ["kx", "EBAS"])
        print("\(g)")
    }

}
