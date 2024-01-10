//
//  DictFile.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation
import WCDBSwift

public final class DictFile {
    public static let `default` = DictFile()
    public init() {}

    // branch node
    public var id: UUID = .default
    public var info: [String: String] = [:]
    public var dict: UUID = .default
    public var fileName: String = .default
    public var hash: UInt64 = .default
    public var finished: Bool = .default
}

extension DictFile: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension DictFile: UUIDNamedTableCodable {
    public static var TableName = "dict_files"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = DictFile
        case id
        case info
        case dict
        case fileName
        case hash
        case finished
        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(info, isNotNull: true, defaultTo: Self.Root.default.info)
            BindColumnConstraint(dict, isNotNull: true, defaultTo: Self.Root.default.dict)
            BindColumnConstraint(fileName, isNotNull: true, defaultTo: Self.Root.default.fileName)
            BindColumnConstraint(hash, isNotNull: true, defaultTo: Self.Root.default.hash)
            BindColumnConstraint(finished, isNotNull: true, defaultTo: Self.Root.default.finished)

            BindForeginKey(
                dict,
                foreignKey: ForeignKey().references(with: Dict.TableName).columns(
                    Dict.Properties.id
                ).onDelete(.cascade))
        }
    }
}
