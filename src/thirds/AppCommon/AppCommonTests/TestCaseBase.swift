//
//  AppCommonTestCase.swift
//  AppCommonTests
//
//  Created by zxq on 2023/9/21.
//

import AppCommon
import XCTest

class TestCaseBase: XCTestCase, DelegatedServicesLocator {
    lazy var tmpDataUrl = {
        FileManager.default.temporaryDirectory.appending(
            path: "\(Self.self)_tmpdata")
    }()

    let register = createServicesContainer()

    lazy var locator = {
        register.build()
    }()
}
