//
//  Node.swift
//  AppCommon
//
//  Created by zxq on 2023/9/21.
//

import Foundation
import WCDBSwift

public protocol ColumnCodableEnum<TRaw>: ExpressionConvertible, ColumnCodable {
    associatedtype TRaw
    var rawValue: TRaw { get }
    init?(rawValue: TRaw)
}

extension ColumnCodableEnum<String> {
    public func asExpression() -> WCDBSwift.Expression {
        Expression(stringLiteral: TRaw(self.rawValue))
    }
}

extension ColumnCodableEnum<String> {
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: value.stringValue)
    }

    public func archivedValue() -> WCDBSwift.Value {
        .init(self.rawValue)
    }

    public static var columnType: WCDBSwift.ColumnType {
        .text
    }
}

extension ColumnCodableEnum<Int> {
    public func asExpression() -> WCDBSwift.Expression {
        Expression(integerLiteral: TRaw(self.rawValue))
    }
}

extension ColumnCodableEnum<Int> {
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }

    public func archivedValue() -> WCDBSwift.Value {
        .init(self.rawValue)
    }

    public static var columnType: WCDBSwift.ColumnType {
        .integer32
    }
}

public enum FileType: String, CaseIterable {
    case none
    case txt
    case pdf
    static let `default`: Self = .none
}

extension FileType: ColumnCodableEnum {

}

public enum NodeType: Int, CaseIterable {
    case branch = 0
    case leaf = 1
    static let `default`: NodeType = .branch
}

extension NodeType: ColumnCodableEnum {

}

public protocol BranchNodeP {
    var id: UUID { get set }
    var name: String { get set }
    var parent: UUID? { get set }
    var path: String { get set }
}

public protocol NodeP: BranchNodeP {
    var type: NodeType { get set }
}
