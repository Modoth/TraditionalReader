//
//  ReadingBook.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/12.
//

import AppCommon
import Foundation
import WCDBSwift

public final class ReadingBook {
    public static let `default` = ReadingBook().with(\.layoutX, 0).with(\.layoutY, 0)
    public init() {}

    public var id: UUID = .default
    public var comment: String?
    public var book: UUID = .default
    public var readingList: UUID = .zero
    public var position: UInt32 = .default
    public var accessed: Date = .default
    /// Range [-1, 1]
    public var layoutX: Double = Double.random(in: -1...1)
    /// Range [-1, 1]
    public var layoutY: Double = Double.random(in: -1...1)
    public var layoutZ: UInt32 = .default
    public var layoutAngle: Double = .default
}

extension ReadingBook: UUIDNamedTableCodable {
    public static var TableName = "opened_books"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = ReadingBook
        case id
        case comment
        case book
        case readingList
        case position
        case accessed

        case layoutX
        case layoutY
        case layoutZ
        case layoutAngle

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(
                id, isPrimary: true, isNotNull: true, defaultTo: Self.Root.default.id)
            //            BindColumnConstraint(comment)
            BindColumnConstraint(book, isNotNull: true, defaultTo: Self.Root.default.book)
            BindColumnConstraint(
                readingList, isNotNull: true, defaultTo: Self.Root.default.readingList)
            BindColumnConstraint(position, isNotNull: true, defaultTo: Self.Root.default.position)
            BindColumnConstraint(accessed, isNotNull: true, defaultTo: Self.Root.default.accessed)
            BindColumnConstraint(layoutX, isNotNull: true, defaultTo: Self.Root.default.layoutX)
            BindColumnConstraint(layoutY, isNotNull: true, defaultTo: Self.Root.default.layoutY)
            BindColumnConstraint(layoutZ, isNotNull: true, defaultTo: Self.Root.default.layoutZ)
            BindColumnConstraint(
                layoutAngle, isNotNull: true, defaultTo: Self.Root.default.layoutAngle)

            BindForeginKey(
                book,
                foreignKey: ForeignKey().references(with: File.TableName).columns(
                    File.Properties.id
                ).onDelete(.cascade))

            BindForeginKey(
                readingList,
                foreignKey: ForeignKey().references(with: ReadingList.TableName).columns(
                    ReadingList.Properties.id
                ).onDelete(.setDefault)
            )
        }
    }
}

public typealias ReadingBooksRepository = UUIDRepository<ReadingBook>
