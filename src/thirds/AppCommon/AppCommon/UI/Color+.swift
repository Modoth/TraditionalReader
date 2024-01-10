//
//  Color+.swift
//  AppCommon
//
//  Created by zxq on 2023/10/21.
//

import Foundation
import SwiftUI

private let _transparent = Color.black.opacity(0)
private let _appBg = Color(
    cgColor: .init(red: 0xF5 / 0xFF, green: 0xF5 / 0xFF, blue: 0xF5 / 0xFF, alpha: 1))
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ShapeStyle where Self == Color {
    public static var transparent: Self {
        _transparent
    }
    public static var appBg: Self {
        _appBg
    }
}
