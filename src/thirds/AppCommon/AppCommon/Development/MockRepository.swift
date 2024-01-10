//
//  MockRepository.swift
//  AppCommon
//
//  Created by zxq on 2023/10/21.
//

import Foundation
import WCDBSwift

open class MockRepository<TItem>: UUIDRepository where TItem: UUIDNamedTableCodable {
    public init() {}
    public var itemsCount: Int { 5 }
    var _items: [TItem]? = nil
    public var items: [TItem] {
        if _items == nil {
            _items = [Int](repeating: 0, count: Int(itemsCount)).map { _ in TItem.mock() }
        }
        return _items!
    }

    private func getItems(take: Int?) -> [TItem] {
        let count = take ?? itemsCount
        if items.count < count {
            let news = [Int](repeating: 0, count: Int(count) - items.count).map { _ in TItem.mock()
            }
            _items!.append(contentsOf: news)
        }
        let end = items.index(0, offsetBy: Int(count))
        return Array(items[0..<end])

    }

    public func create(_ item: TItem) throws {}
    public func create(_ items: [TItem]) throws {}
    public func read(skip: Int?, take: Int?, orderBy: TItem.CodingKeys?, orderByDesc: Bool?)
        throws
        -> [TItem]
    { return getItems(take: take) }
    public func read<TValue>(
        by: TItem.CodingKeys, value: TValue?, skip: Int?, take: Int?,
        orderBy: TItem.CodingKeys?,
        orderByDesc: Bool?
    ) throws
        -> [TItem]
    where TValue: WCDBSwift.ExpressionConvertible {
        return getItems(take: take)
    }
    public func read(
        where: WCDBSwift.Condition, skip: Int?, take: Int?, orderBy: TItem.CodingKeys?,
        orderByDesc: Bool?
    ) throws -> [TItem] {
        return getItems(take: take)
    }
    public func update(_ item: TItem, bys: [TItem.CodingKeys]?) throws {}
    public func delete<TValue>(by: TItem.CodingKeys, value: TValue?) throws
    where TValue: WCDBSwift.ExpressionConvertible {
    }
}

public func MockRepository$1<TItem: UUIDNamedTableCodable>(_ item: TItem) -> () -> (
    any Repository<TItem>
)
where TItem: UUIDNamedTableCodable {
    {
        MockRepository<TItem>() as any Repository<TItem>
    }
}
