//
//  CopyWithable.swift
//  AppCommon
//
//  Created by zxq on 2023/10/18.
//

import Foundation

public protocol Withable {}
extension Withable {
    public func with<Value>(_ path: ReferenceWritableKeyPath<Self, Value>, _ value: Value) -> Self {
        self[keyPath: path] = value
        return self
    }
}

public protocol CopyWithable {}
extension CopyWithable {
    public func with<T>(_ path: WritableKeyPath<Self, T>, _ value: T) -> Self {
        var copy = self
        copy[keyPath: path] = value
        return copy
    }
}
