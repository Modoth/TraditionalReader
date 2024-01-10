//
//  Dict.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation
import WCDBSwift

public final class Dict {
    public static let `default` = Dict()
    public init() {}

    // branch node
    public var id: UUID = .default
    public var namespace: String = .default
    public var fileName: String = .default
}

extension Dict: UUIDNamedTableCodable {
    public static var TableName = "dicts"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = Dict
        case id
        case namespace
        case fileName

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            //            BindColumnConstraint(parentId)
            BindColumnConstraint(namespace, isNotNull: true, defaultTo: Self.Root.default.namespace)
            BindColumnConstraint(fileName, isNotNull: true, defaultTo: Self.Root.default.fileName)
            BindIndex(
                namespace, fileName,
                namedWith:
                    "_\(Self.Root.Properties.namespace.stringValue)_\(Self.Root.Properties.fileName.stringValue)_Index"
            )
        }
    }
}
