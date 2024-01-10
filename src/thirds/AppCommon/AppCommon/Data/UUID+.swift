//
//  UUID+ColumnCodable.swift
//  AppCommon
//
//  Created by zxq on 2023/9/19.
//

import Foundation
import WCDBSwift

extension UUID: ColumnCodable {
    public init?(with value: WCDBSwift.Value) {
        self.init(uuidString: value.stringValue)
    }

    public func archivedValue() -> WCDBSwift.Value {
        .init(self.uuidString)
    }

    public static var columnType: WCDBSwift.ColumnType {
        .text
    }
}

extension UUID: ExpressionConvertible {
    public func asExpression() -> WCDBSwift.Expression {
        Expression(stringLiteral: self.uuidString)
    }
}
