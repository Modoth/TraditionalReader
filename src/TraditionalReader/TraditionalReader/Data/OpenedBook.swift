//
//  OpenedBook.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/12.
//

import AppCommon
import Foundation
import WCDBSwift

public final class ReadingBook {
    public init() {}

    public var id: UUID = .default
    public var name: String?
    public var bookId: UUID?
    public var deskId: UUID?
    public var position: UInt?
    public var accessed: Date?
}

extension ReadingBook: UUIDNamedTableCodable {
    public static var TableName = "opened_books"
    public enum CodingKeys: String, CodingTableKey, UUIDTableCodingKeys {
        public typealias Root = ReadingBook
        case id
        case name
        case bookId
        case deskId
        case position
        case accessed

        public static let objectRelationalMapping = TableBinding(Self.self) {
            BindColumnConstraint(id, isPrimary: true)
            BindColumnConstraint(deskId, defaultTo: UUID.zero)
            BindForeginKey(
                bookId,
                foreignKey: ForeignKey().references(with: File.TableName).columns(
                    File.Properties.id
                ).onDelete(.cascade))
            BindForeginKey(
                deskId,
                foreignKey: ForeignKey().references(with: ReadingList.TableName).columns(
                    ReadingList.Properties.id
                ).onDelete(.setDefault)
            )
        }
    }
}

public let OpenedBooksRepository$ = {
    OpenedBooksRepositoryImpl() as any OpenedBooksRepository
}

public protocol OpenedBooksRepository: UUIDRepository<ReadingBook> {

}

private class OpenedBooksRepositoryImpl: UUIDRepositoryBase<ReadingBook>, OpenedBooksRepository {

}
