//
//  DictSection.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation
import WCDBSwift

public final class DictSection {
    public static let `default` = DictSection()
    public init() {}

    // branch node
    public var id: UUID = .default
    public var file: UUID = .default
    public var metaInfo: UInt64 = .default
    public var start: UInt64 = .default
    public var end: UInt64 = .default
}

extension DictSection: UUIDNamedTableCodable {
    public static var TableName = "dict_sections"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = DictSection
        case id
        case file
        case metaInfo
        case start
        case end

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(file, isNotNull: true, defaultTo: Self.Root.default.file)
            BindColumnConstraint(metaInfo, isNotNull: true, defaultTo: Self.Root.default.metaInfo)
            BindColumnConstraint(file, isNotNull: true, defaultTo: Self.Root.default.file)
            BindColumnConstraint(start, isNotNull: true, defaultTo: Self.Root.default.start)
            BindColumnConstraint(end, isNotNull: true, defaultTo: Self.Root.default.end)

            BindForeginKey(
                file,
                foreignKey: ForeignKey().references(with: DictFile.TableName).columns(
                    DictFile.Properties.id
                ).onDelete(.cascade))
        }
    }
}
