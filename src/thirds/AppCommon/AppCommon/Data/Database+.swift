//
//  Database+.swift
//  AppCommon
//
//  Created by zxq on 2023/10/13.
//

import Foundation
import WCDBSwift

extension Database {
    public func createTable<T: NamedTableCodable>(_: T.Type) throws {
        try self.create(table: T.TableName, of: T.self)
    }
    public func createVirtualTable<T: NamedTableCodable>(_: T.Type) throws {
        try self.create(virtualTable: T.TableName, of: T.self)
    }
}
