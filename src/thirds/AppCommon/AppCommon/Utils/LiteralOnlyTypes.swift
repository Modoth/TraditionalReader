//
//  LiteralOnlyTypes.swift
//  AppCommon
//
//  Created by zxq on 2023/10/26.
//

import Foundation

postfix operator %!
postfix operator %?

public protocol LiteralOnlyType {
    associatedtype Value
    var value: Value { get }
}

extension LiteralOnlyType {
    public static postfix func %! (wraper: Self) -> Value {
        wraper.value
    }
}

extension Optional where Wrapped: LiteralOnlyType {
    public var value: Wrapped.Value? {
        return self?.value ?? nil
    }

    public static postfix func %? (wraper: Self) -> Wrapped.Value? {
        wraper.value
    }
}

public enum LiteralOnlyBool: ExpressibleByBooleanLiteral, LiteralOnlyType {
    public typealias BooleanLiteralType = Bool

    public init(booleanLiteral value: Bool) {
        self = value ? .true : .false
    }

    static let `default`: Self = .false

    case `false`
    case `true`
    public var value: Bool {
        switch self {
        case .false:
            false
        case .true:
            true
        }
    }

    public static prefix func ! (b: LiteralOnlyBool) -> LiteralOnlyBool {
        return b == .false ? .true : .false
    }

    public static func && (lhs: Self, rhs: Self) -> Self {
        return lhs.value && rhs.value ? .true : .false
    }

    public static func || (lhs: Self, rhs: Self) -> Self {
        return lhs.value || rhs.value ? .true : .false
    }
}

precedencegroup SecondaryTernaryPrecedence {
    associativity: right
    higherThan: TernaryPrecedence
    lowerThan: LogicalDisjunctionPrecedence
}

infix operator |?| : SecondaryTernaryPrecedence
infix operator <> : TernaryPrecedence

public func |?| <T>(lhs: @autoclosure () -> LiteralOnlyBool, rhs: @escaping @autoclosure () -> T)
    -> (LiteralOnlyBool, () -> T)
{
    (lhs(), rhs)
}

@discardableResult public func <> <T>(
    lhs: (LiteralOnlyBool, () -> T), rhs: @escaping @autoclosure () -> T
) -> T {
    lhs.0.value ? lhs.1() : rhs()
}

public struct LiteralOnlyInt: ExpressibleByIntegerLiteral, LiteralOnlyType {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self.value = value
    }

    public let value: Int

    static let `default`: Self = 0
}
