//
//  DataReader.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation

public protocol BufferSource {
    associatedtype Index: FixedWidthInteger
    subscript(_ idx: Index, count: Int) -> [UInt8] { get }
    var count: Index { get }
}

extension [UInt8]: BufferSource {
    public subscript(_ idx: Int, count: Int) -> [UInt8] {
        return Array(self[idx..<idx + count])
    }
}

extension LazyData: BufferSource {

}

public protocol DataSimpleReadable {}

public class DataReader<Buffer: BufferSource> {
    public typealias Index = Buffer.Index
    public let data: Buffer
    public var position: Index = 0
    public init(_ data: Buffer) {
        self.data = data
    }
    public func get<TInt: FixedWidthInteger>(_ offset: Index, _ be: Bool = false) -> TInt {
        let value = getBuffer(offset, count: TInt.bitWidth / 8).withUnsafeBytes {
            $0.load(as: TInt.self)
        }
        if be == isBigEndian {
            return value
        }
        if be {
            return TInt(bigEndian: value)
        }
        return TInt(littleEndian: value)
    }

    public func getBuffer(_ offset: Index, count: Int) -> [UInt8] {
        return self.data[offset, count]
    }

    public func read<TInt: FixedWidthInteger>(_ be: Bool = false) -> TInt {
        let value: TInt = get(position, be)
        position += Buffer.Index(TInt.bitWidth / 8)
        return value
    }

    public func read() -> UUID {
        let uuid = readBuffer(count: 16).withUnsafeBytes {
            $0.load(as: uuid_t.self)
        }
        return UUID(uuid: uuid)
    }

    public func read<T: DataSimpleReadable>() -> T {
        let count = MemoryLayout<T>.size
        let buffer = readBuffer(count: count)
        return buffer.withUnsafeBytes {
            $0.load(as: T.self)
        }
    }

    public func read(_ encoding: String.Encoding = .utf8) -> String {
        precondition(encoding == .utf8)
        var buffer: [UInt8] = []
        var cur = position
        while true {
            if cur >= data.count {
                break
            }
            let u = data[cur, 1][0]
            cur += 1
            if u == 0 {
                break
            }
            buffer.append(u)
        }
        position = cur
        return String(bytes: buffer, encoding: encoding) ?? ""
    }

    public func readBuffer(count: Int) -> [UInt8] {
        let buffer = getBuffer(position, count: count)
        position += Buffer.Index(count)
        return buffer
    }
}
