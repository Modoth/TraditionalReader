//
//  DictItem.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation
import WCDBSwift

public final class DictItem {
    public static let `default` = DictItem()
    public init() {}

    // branch node
    public var id: UUID = .default
    public var dict: UUID = .default
    /// querable
    public var title: String = .default
    /// identitable
    public var key: String = .default
    public var section: UUID = .default
    public var start: UInt64 = .default
    public var end: UInt64 = .default
}

extension DictItem: UUIDNamedTableCodable {
    public static var TableName = "dict_items"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = DictItem
        case id
        case dict
        case title
        case key
        case section
        case start
        case end

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(dict, isNotNull: true, defaultTo: Self.Root.default.dict)
            BindColumnConstraint(title, isNotNull: true, defaultTo: Self.Root.default.title)
            BindColumnConstraint(key, isNotNull: true, defaultTo: Self.Root.default.key)
            BindColumnConstraint(section, isNotNull: true, defaultTo: Self.Root.default.section)
            BindColumnConstraint(start, isNotNull: true, defaultTo: Self.Root.default.start)
            BindColumnConstraint(end, isNotNull: true, defaultTo: Self.Root.default.end)

            BindIndex(title, namedWith: "_\(Self.Root.Properties.title.stringValue)_Index")
            BindIndex(key, namedWith: "_\(Self.Root.Properties.key.stringValue)_Index")

            BindForeginKey(
                dict,
                foreignKey: ForeignKey().references(with: Dict.TableName).columns(
                    Dict.Properties.id
                ).onDelete(.cascade))
            BindForeginKey(
                section,
                foreignKey: ForeignKey().references(with: DictSection.TableName).columns(
                    DictSection.Properties.id
                ).onDelete(.cascade))
        }
    }
}
