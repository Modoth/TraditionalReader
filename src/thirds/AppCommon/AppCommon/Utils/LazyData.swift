//
//  LazyData.swift
//  AppCommon
//
//  Created by zxq on 2023/11/7.
//

import Foundation

public class LazyDataSlice<Index: FixedWidthInteger>: Sequence, IteratorProtocol {
    let data: LazyData<Index>
    let start: Index
    let end: Index
    var current: Index = 0
    init(data: LazyData<Index>, start: Index, end: Index) {
        self.data = data
        self.start = start
        self.end = end
    }
    public func next() -> UInt8? {
        let idx = start + current
        if idx >= end {
            return nil
        }
        current += 1
        return data[idx]
    }
    public typealias Element = UInt8
}

public class LazyData<Index: FixedWidthInteger> {
    private let perCacheSize: Int
    private let perCacheSizeIndex: Index
    private let perCacheSize64: UInt64
    private var caches: [Index: Data] = [:]
    private var fileHandle: FileHandle
    public private(set) var count: Index = 0
    public init(contentsOf url: URL, perCacheSize: Int = 1 << 16) throws {
        self.perCacheSize = perCacheSize
        self.perCacheSize64 = UInt64(perCacheSize)
        self.perCacheSizeIndex = Index(perCacheSize)
        let attr = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        guard let fileSize = attr[FileAttributeKey.size] as? Index else {
            throw URLError(.cannotOpenFile)
        }
        count = fileSize
        fileHandle = try FileHandle(forReadingFrom: url)
    }

    deinit {
        try? fileHandle.close()
    }

    public subscript(_ idx: Index) -> UInt8 {
        precondition(idx < count)
        let (cacheId, subId) = (idx / (perCacheSizeIndex), idx % perCacheSizeIndex)
        guard let cache = try? getCache(cacheId) else {
            fatalError()
        }
        return cache[Int(subId)]
    }

    public subscript(_ idx: Index, count: Int) -> [UInt8] {
        precondition(count >= 0)
        var data: [UInt8] = .init(repeating: 0, count: count)
        for i in 0..<count {
            data[i] = self[idx + Index(i)]
        }
        return data
    }

    public subscript(_ range: Range<Index>) -> LazyDataSlice<Index> {
        return LazyDataSlice(data: self, start: range.lowerBound, end: range.upperBound)
    }

    private func getCache(_ cacheId: Index) throws -> Data {
        let cache = caches[cacheId]
        if cache != nil {
            return cache!
        }
        try fileHandle.seek(toOffset: UInt64(cacheId) * perCacheSize64)
        guard let data = try fileHandle.read(upToCount: perCacheSize) else {
            throw URLError(.cannotOpenFile)
        }
        caches[cacheId] = data
        return data
    }
}
