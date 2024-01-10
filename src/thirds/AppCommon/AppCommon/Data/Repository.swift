//
//  Repository.swift
//  AppCommon
//
//  Created by zxq on 2023/9/19.
//

import Foundation
import WCDBSwift

public protocol NamedTable: Withable {
    static var TableName: String { get }
}

public typealias NamedTableCodable = TableEncodable & TableDecodable & NamedTable

public protocol UUIDTableCodingKeys {
    static var id: Self { get }
}

public protocol UUIDNamedTableCodable: Equatable, NamedTableCodable
where CodingKeys: UUIDTableCodingKeys {
    var id: UUID { get set }
}

extension UUIDNamedTableCodable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public protocol Repository<TItem>: Service {
    associatedtype TItem: NamedTableCodable
    func create(_ item: TItem) throws
    func create(_ items: [TItem]) throws
    func read(
        skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws -> [TItem]
    func read<TValue: ExpressionConvertible>(
        by: TItem.CodingKeys, value: TValue?, skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws
        -> [TItem]

    func read(
        where: Condition,
        skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws -> [TItem]
    func delete<TValue: ExpressionConvertible>(by: TItem.CodingKeys, value: TValue?) throws
}

public protocol UUIDRepository<TItem>: Repository where TItem: UUIDNamedTableCodable {
    func createIds(count: Int) throws -> [UUID]
    func update(_ item: TItem, bys: [TItem.CodingKeys]?) throws
}

extension Repository {
    public func readOne<TValue: ExpressionConvertible>(by: TItem.CodingKeys, value: TValue?) throws
        -> TItem?
    {
        (try read$(by: by, value: value, take: 1)).first
    }
    public func readOne(where: Condition) throws
        -> TItem?
    {
        (try read$(where: `where`, take: 1)).first
    }

    public func checkExisted<TValue: ExpressionConvertible>(by: TItem.CodingKeys, value: TValue?)
        throws
        -> Bool
    {
        (try read$(by: by, value: value, take: 1)).first != nil
    }

    public func read$(
        skip: Int? = nil, take: Int? = nil,
        orderBy: TItem.CodingKeys? = nil, orderByDesc: Bool? = nil
    ) throws -> [TItem] {
        try read(skip: skip, take: take, orderBy: orderBy, orderByDesc: orderByDesc)
    }

    public func read$<TValue: ExpressionConvertible>(
        by: TItem.CodingKeys, value: TValue?, skip: Int? = nil, take: Int? = nil,
        orderBy: TItem.CodingKeys? = nil, orderByDesc: Bool? = nil
    ) throws -> [TItem] {
        try read(
            by: by, value: value, skip: skip, take: take, orderBy: orderBy, orderByDesc: orderByDesc
        )
    }

    func read$(
        where: Condition,
        skip: Int? = nil, take: Int? = nil,
        orderBy: TItem.CodingKeys? = nil, orderByDesc: Bool? = nil
    ) throws -> [TItem] {
        try read(where: `where`, skip: skip, take: take, orderBy: orderBy, orderByDesc: orderByDesc)
    }
}

extension UUIDRepository {
    public func createIds(count: Int) throws -> [UUID] {
        precondition(count > 0)
        let maxTryTimes = 3
        var ids: Set<UUID> = []
        ids: for _ in 0..<count {
            for _ in 0..<maxTryTimes {
                let id = UUID()
                if !ids.contains(id)
                    && (try? readOne(by: Self.TItem.CodingKeys.id, value: id)) == nil
                {
                    ids.insert(id)
                    continue ids
                }
            }
            throw BusinessError(.failed)
        }
        return Array(ids)
    }

    public func update(_ item: TItem, bys: [TItem.CodingKeys]? = nil) throws {
        try update(item, bys: bys)
    }

    public func delete(_ item: TItem) throws {
        try delete(by: .id, value: item.id)
    }
}

open class RepositoryBase<TItem: NamedTableCodable>: Repository {
    public init() {

    }

    public typealias TItem = TItem

    public func create(_ item: TItem) throws {
        let database: Database = locate()
        try database.insert(item, intoTable: TItem.TableName)
    }

    public func create(_ items: [TItem]) throws {
        let database: Database = locate()
        try database.insert(items, intoTable: TItem.TableName)
    }

    public func read(
        skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws -> [TItem] {
        let database: Database = locate()
        return try database.getObjects(
            fromTable: TItem.TableName,
            orderBy: buildOrder(orderBy, orderByDesc),
            limit: take,
            offset: skip)
    }

    public func read(
        where: Condition,
        skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws -> [TItem] {
        let database: Database = locate()
        return try database.getObjects(
            fromTable: TItem.TableName,
            where: `where`,
            orderBy: buildOrder(orderBy, orderByDesc),
            limit: take,
            offset: skip)
    }

    public func read<TValue: ExpressionConvertible>(
        by: TItem.CodingKeys, value: TValue?, skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?, orderByDesc: Bool?
    ) throws
        -> [TItem]
    {
        let database: Database = locate()
        if value == nil {
            return try database.getObjects(
                fromTable: TItem.TableName,
                where: Expression(with: Column(named: by.rawValue)).isNull(),
                orderBy: buildOrder(orderBy, orderByDesc),
                limit: take,
                offset: skip
            )
        } else {
            return try database.getObjects(
                fromTable: TItem.TableName,
                where: Expression(with: Column(named: by.rawValue)) == value!,
                orderBy: buildOrder(orderBy, orderByDesc),
                limit: take,
                offset: skip
            )
        }
    }

    public func delete<TValue: ExpressionConvertible>(by: TItem.CodingKeys, value: TValue?) throws {
        let database: Database = locate()
        if value == nil {
            try database.delete(
                fromTable: TItem.TableName,
                where: Expression(with: Column(named: by.rawValue)).isNull()
            )
        } else {
            try database.delete(
                fromTable: TItem.TableName,
                where: Expression(with: Column(named: by.rawValue)) == value!
            )
        }
    }

    private func buildOrder(_ by: TItem.CodingKeys?, _ desc: Bool?) -> [OrderingTerm]? {
        if by == nil {
            return nil
        }
        let order = by!.asOrder()
        return desc == true ? [order.order(.descending)] : [order]
    }
}

open class UUIDRepositoryBase<TItem: UUIDNamedTableCodable>: RepositoryBase<TItem>, UUIDRepository {
    public func update(_ item: TItem, bys: [TItem.CodingKeys]?) throws {
        let database: Database = locate()
        if bys == nil || bys!.count == 0 {
            try database.insertOrReplace(item, intoTable: TItem.TableName)
            return
        }
        try database.update(
            table: TItem.TableName, on: bys!, with: item,
            where: Expression(with: Column(named: TItem.CodingKeys.id.rawValue)) == item.id)
    }
}

public func Repository$<TItem: NamedTableCodable>(_ item: TItem) -> () -> (any Repository<TItem>) {
    {
        RepositoryBase<TItem>() as any Repository<TItem>
    }
}

public func UUIDRepository$<TItem: UUIDNamedTableCodable>(_ item: TItem) -> () -> (
    any UUIDRepository<TItem>
) {
    {
        UUIDRepositoryBase<TItem>() as any UUIDRepository<TItem>
    }
}
