//
//  ArrayOrElement.swift
//  AppCommon
//
//  Created by zxq on 2023/10/27.
//

import Foundation

public protocol ArrayOrElement<Element> {
    associatedtype Element
    func traitAsArray() -> [Element]
}

extension Array: ArrayOrElement {
    public func traitAsArray() -> [Element] {
        self
    }
}

extension ArrayOrElement {
    public func traitAsArray() -> [Self] {
        [self]
    }
}

extension Int: ArrayOrElement {

}

@resultBuilder
public struct ArrayBuilder<Element> {

    public static func buildBlock() -> [Element] {
        []
    }
    public static func buildBlock(_ components: (any ArrayOrElement<Element>)...) -> [Element] {
        components.map { $0.traitAsArray() }.flatMap { $0 }
    }
    public static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }
    public static func buildEither(first component: [Element]) -> [Element] {
        component
    }
    public static func buildEither(second component: [Element]) -> [Element] {
        component
    }
}

extension Array {
    public static func from(@ArrayBuilder<Element> _ factory: () -> Self) -> Self {
        factory()
    }
}
