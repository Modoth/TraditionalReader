//
//  MockDecoder.swift
//  AppCommon
//
//  Created by zxq on 2023/10/21.
//

import Foundation
import WCDBSwift

public protocol RandMockable: Decodable {
    static func randMock() -> Self
}

extension UUID: RandMockable {
    public static func randMock() -> UUID {
        UUID()
    }
}

let MAX_DATE = Date().timeIntervalSince1970 * 2
extension Date: RandMockable {
    public static func randMock() -> Date {
        Date(timeIntervalSince1970: Double.random(in: 0..<MAX_DATE))
    }
}

extension CaseIterable {
    public static func randMock() -> Self {
        Self.allCases.randomElement()!
    }
}

extension NodeType: RandMockable {

}

extension FileType: RandMockable {

}

extension UUIDNamedTableCodable {
    public static func mock() -> Self {
        try! Self(from: MockDecoder())
    }
}

public class MockDecoder: Decoder {

    private var container: Any?

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
    where Key: CodingKey {
        if container == nil {
            container = KeyedDecodingContainer(MockKeyedDecodingTableContainer<Key>())
        }
        return container as! KeyedDecodingContainer<Key>
    }

    private final class MockKeyedDecodingTableContainer<CodingKeys: CodingKey>:
        KeyedDecodingContainerProtocol
    {
        typealias Key = CodingKeys

        func contains(_ key: CodingKeys) -> Bool {
            return true
        }

        func decodeNil(forKey key: CodingKeys) throws -> Bool {
            Int.random(in: 0..<4) < 1
        }

        func decode(_ type: Bool.Type, forKey key: CodingKeys) throws -> Bool {
            [true, false].randomElement()!
        }

        func decode(_ type: String.Type, forKey key: CodingKeys) throws -> String {
            randStr(Int.random(in: 1..<8))
        }

        func decode(_ type: Double.Type, forKey key: CodingKeys) throws -> Double {
            Double.random(in: -100.0...100.0)
        }

        func decode(_ type: Float.Type, forKey key: CodingKeys) throws -> Float {
            Float.random(in: -100.0...100.0)
        }

        func decode(_ type: Int.Type, forKey key: CodingKeys) throws -> Int {
            Int.random(in: Int.min...Int.max)
        }

        func decode(_ type: Int8.Type, forKey key: CodingKeys) throws -> Int8 {
            Int8.random(in: Int8.min...Int8.max)
        }

        func decode(_ type: Int16.Type, forKey key: CodingKeys) throws -> Int16 {
            Int16.random(in: Int16.min...Int16.max)
        }

        func decode(_ type: Int32.Type, forKey key: CodingKeys) throws -> Int32 {
            Int32.random(in: Int32.min...Int32.max)
        }

        func decode(_ type: Int64.Type, forKey key: CodingKeys) throws -> Int64 {
            Int64.random(in: Int64.min...Int64.max)
        }

        func decode(_ type: UInt.Type, forKey key: CodingKeys) throws -> UInt {
            UInt.random(in: UInt.min...UInt.max)
        }

        func decode(_ type: UInt8.Type, forKey key: CodingKeys) throws -> UInt8 {
            UInt8.random(in: UInt8.min...UInt8.max)
        }

        func decode(_ type: UInt16.Type, forKey key: CodingKeys) throws -> UInt16 {
            UInt16.random(in: UInt16.min...UInt16.max)
        }

        func decode(_ type: UInt32.Type, forKey key: CodingKeys) throws -> UInt32 {
            UInt32.random(in: UInt32.min...UInt32.max)
        }

        func decode(_ type: UInt64.Type, forKey key: CodingKeys) throws -> UInt64 {
            UInt64.random(in: UInt64.min...UInt64.max)
        }

        func decode<T>(_ type: T.Type, forKey key: CodingKeys) throws -> T where T: Decodable {
            let randMockT = T.self as? RandMockable.Type
            if randMockT != nil {
                return randMockT?.randMock() as! T
            }

            //            let enumT = T.self as? (any CaseIterable).Type
            //            if enumT != nil {
            //                let i : any enumT.Self = enumT!.AllCases.randomElement()
            //            }
            fatalError("")
        }

        var codingPath: [CodingKey] {
            fatalError("")
        }

        var allKeys: [CodingKeys] {
            fatalError("")
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: CodingKeys) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey
        {
            fatalError("")
        }

        func nestedUnkeyedContainer(forKey key: CodingKeys) throws -> UnkeyedDecodingContainer {
            fatalError("")
        }

        func superDecoder() throws -> Decoder {
            fatalError("")
        }

        func superDecoder(forKey key: CodingKeys) throws -> Decoder {
            fatalError("")
        }
    }

    public var codingPath: [CodingKey] {
        fatalError("")
    }

    public var userInfo: [CodingUserInfoKey: Any] {
        fatalError("")
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("")
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError("")
    }
}
