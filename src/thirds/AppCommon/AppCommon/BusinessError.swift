//
//  BusinessError.swift
//  AppCommon
//
//  Created by zxq on 2023/9/22.
//

import Foundation
import SwiftUI

extension LocalizedStringKey {

}

public struct BusinessErrorType: Equatable {
    public let stringKey: LocalizedStringKey
    public init(_ stringKey: LocalizedStringKey) {
        self.stringKey = stringKey
    }
}

public struct BusinessError: Error {
    public static let `default` = BusinessError(.failed)
    public let type: BusinessErrorType
    public init(_ type: BusinessErrorType) {
        self.type = type
    }
}

extension BusinessErrorType {
    #if DEBUG
        public static let notImplemented: Self = .init(
            LocalizedStringKey("BusinessErrorType.NotImplemented"))
    #endif
    public static var fatalError: Self = .init(LocalizedStringKey("BusinessErrorType.FatalError"))
    public static var failed: Self = .init(LocalizedStringKey("BusinessErrorType.Failed"))
    public static var nameExisted: Self = .init(LocalizedStringKey("BusinessErrorType.NameExisted"))
    public static var fileExisted: Self = .init(LocalizedStringKey("BusinessErrorType.FileExisted"))
    public static var invalidName: Self = .init(LocalizedStringKey("BusinessErrorType.InvalidName"))
    public static var createFailed: Self = .init(
        LocalizedStringKey("BusinessErrorType.CreateFailed"))
}
