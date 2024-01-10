//
//  ReadingPanel.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/19.
//

import AppCommon
import Foundation
import WCDBSwift

public enum ReadingPanelType: String, CaseIterable {
    case book
    case web
    case dictionary
    public static let `default`: Self = .dictionary
}

extension ReadingPanelType: ColumnCodableEnum {}

public enum ReadingPanelSize: Int, CaseIterable, ColumnCodableEnum {
    case small = 1
    case normal
    case large
    public static let `default`: Self = .normal
}

extension ReadingPanelSize {
    public func asExpression() -> WCDBSwift.Expression {
        Expression(integerLiteral: Int(self.rawValue))
    }
}

extension ReadingPanelSize {
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

//extension ReadingPanelSize: ColumnCodableEnum {}

public final class ReadingPanel {
    public static let `default` = ReadingPanel()
    public init() {}
    public var id: UUID = .default
    public var readingList: UUID = .default
    public var type: ReadingPanelType = .default
    public var content: UUID?
    public var pOrder: UInt8 = .default
    public var size: ReadingPanelSize = .default
}

extension ReadingPanel: UUIDNamedTableCodable {
    public static var TableName = "reading_panels"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = ReadingPanel
        case id
        case readingList
        case type
        case content
        case pOrder
        case size

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            BindColumnConstraint(
                readingList, isNotNull: true, defaultTo: Self.Root.default.readingList)
            BindColumnConstraint(
                type, isNotNull: true, defaultTo: Self.Root.default.type)
            //            BindColumnConstraint(openedBookId)
            BindColumnConstraint(pOrder, isNotNull: true, defaultTo: Self.Root.default.pOrder)
            BindColumnConstraint(size, isNotNull: true, defaultTo: Self.Root.default.size)

            BindForeginKey(
                readingList,
                foreignKey: ForeignKey().references(with: ReadingList.TableName).columns(
                    ReadingList.Properties.id
                ).onDelete(.cascade))

            BindForeginKey(
                content,
                foreignKey: ForeignKey().references(with: ReadingBook.TableName).columns(
                    ReadingBook.Properties.id
                ).onDelete(.setNull))
        }
    }
}

public typealias ReadingPanelsRepository = UUIDRepository<ReadingPanel>
