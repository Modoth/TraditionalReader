//
//  ReadingList.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/12.
//

import AppCommon
import Foundation
import WCDBSwift

public final class ReadingList {
    public static let `default` = ReadingList()
    public init() {}

    public var id: UUID = .default
    public var name: String = .default
    public var accessed: Date = .default
}

extension ReadingList: UUIDNamedTableCodable {
    public static var TableName = "reading_lists"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = ReadingList
        case id
        case name
        case accessed

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(name, isNotNull: true, defaultTo: Self.Root.default.name)
            BindColumnConstraint(
                accessed, isNotNull: true, isUnique: true, defaultTo: Self.Root.default.name)
        }
    }
}

public typealias ReadingListsRepository = Repository<ReadingList>
