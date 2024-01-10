//
//  Generators.swift
//  AppCommon
//
//  Created by zxq on 2023/9/22.
//

import Foundation

public func randStrEn(_ length: Int) -> String {
    return String((0..<length).map { _ in lettersEn.randomElement()! })
}

public func randStr(_ length: Int) -> String {
    return String((0..<length).map { _ in letters.randomElement()! })
}
