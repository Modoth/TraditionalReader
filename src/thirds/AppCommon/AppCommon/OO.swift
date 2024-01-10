//
//  OO.swift
//  AppCommon
//
//  Created by zxq on 2023/9/22.
//

import Foundation
import SwiftUI

postfix operator %!

public class OO<T>: ObservableObject {
    public let value: T
    public init(_ value: T) {
        self.value = value
    }

    @inlinable public static postfix func %! (vector: OO) -> T {
        vector.value
    }
}

extension OO: Equatable where T: Equatable {
    public static func == (lhs: OO<T>, rhs: OO<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension OO: ServicesLocator, DelegatedServicesLocator where T: ServicesLocator {
    public var locator: ServicesLocator { self%! }
}

extension View {
    @inlinable public func environmentOo<T>(_ obj: T) -> some View {
        self.environmentObject(OO(obj))
    }
}
