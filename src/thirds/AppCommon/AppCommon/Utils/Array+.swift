//
//  Array+.swift
//  AppCommon
//
//  Created by zxq on 2023/10/27.
//

import Foundation

public protocol OptionalProtocol {
    associatedtype Wrapped
    var optional: Wrapped? { get }
}

extension Optional: OptionalProtocol {
    public var optional: Wrapped? {
        return self
    }
}

postfix operator %!
postfix operator %?

extension Array where Element: OptionalProtocol {
    @inlinable public static postfix func %! (wraper: Self) -> [Element.Wrapped] {
        return wraper.notNils()
    }

    @inlinable public func notNils() -> [Element.Wrapped] {
        return self.filter { $0.optional != nil }.map { $0.optional! }
    }
}

extension Array {
    public func tryGet(_ idx: Int) -> Element? {
        if idx >= 0 && idx < self.count {
            return self[idx]
        }
        return nil
    }
}
