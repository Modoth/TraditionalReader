//
//  CharsSequence.swift
//  AppCommon
//
//  Created by zxq on 2023/11/8.
//

import Foundation

public protocol CharsSequence: Sequence, IteratorProtocol {
    var count: Int { get }
    var offset: Int { get }
    func search(_ str: String, latestBefore offset: Int, maxSearch: Int?) -> Range<Int>?
    func seek(nearBefore offset: Int)
    func seek(nearAfter offset: Int)
    func seek(_ offset: Int)
    func setIterEnd(_ iterEndOffset: Int?)
    func saveOffset()
    func loadOffset()
    func seekToPreviousOffset()
    subscript(_ range: Range<Int>) -> String? { get }
    func next() -> (Int, Character)?
}

public class SeekableBase {

    fileprivate var offsets: [Int] = []
    public fileprivate(set) var offset: Int = 0
    fileprivate var iterEndOffset: Int? = nil

    public func search(_ str: String, latestBefore offset: Int, maxSearch: Int?) -> Range<Int>? {
        fatalError("Not implemented")
    }
    public func seek(_ offset: Int) {
        self.offset = offset
    }

    public func setIterEnd(_ iterEndOffset: Int?) {
        self.iterEndOffset = iterEndOffset
    }

    public func seek(nearBefore offset: Int) {
        seek(offset)
    }

    public func seek(nearAfter offset: Int) {
        seek(offset)
    }

    public func saveOffset() {
        offsets.append(offset)
    }

    public func loadOffset() {
        offset = offsets.popLast()!
    }

    public func seekToPreviousOffset() {
        offset = offsets.last!
    }
}

public class FileCharsSequence: SeekableBase, CharsSequence {
    public typealias Element = (Int, Character)
    public private(set) var count: Int
    private let data: LazyData<Int>
    private let encoding: String.Encoding

    public init(_ url: URL, encoding: String.Encoding = .utf8) throws {
        precondition(encoding == .utf8)
        self.encoding = encoding
        self.data = try LazyData(contentsOf: url)
        self.count = self.data.count
    }

    public subscript(_ range: Range<Int>) -> String? {
        return String(bytes: data[range], encoding: encoding)
    }

    public override func search(_ str: String, latestBefore offset: Int, maxSearch: Int?) -> Range<
        Int
    >? {
        let bytes: [UInt8] = Array(str.utf8)
        if bytes.isEmpty {
            return offset..<offset + 1
        }
        for i in 0..<Swift.min(maxSearch ?? (offset + 1), offset + 1) {
            let start = offset - i
            var match = true
            for (j, byte) in bytes.enumerated() {
                let idx = start + j
                if idx >= count || data[idx] != byte {
                    match = false
                    break
                }
            }
            if match {
                return start..<start + bytes.count
            }
        }
        return nil
    }

    public override func seek(nearBefore offset: Int) {
        for i in 0..<maxCodeLength {
            let validOffset = offset - i
            if validOffset == 0 || isStartCode(data[validOffset]) {
                seek(validOffset)
                return
            }
        }
        seek(count)
    }

    public override func seek(nearAfter offset: Int) {
        for i in 0..<maxCodeLength {
            let validOffset = offset + i
            if validOffset >= count {
                seek(count)
                return
            }
            if isStartCode(data[validOffset]) {
                seek(validOffset)
                return
            }
        }
        seek(count)
    }

    private func isStartCode(_ u: UInt8) -> Bool {
        u & 0b10000000 == 0 || u & 0b11000000 == 0b11000000
    }

    private func isNotStartCode(_ u: UInt8) -> Bool {
        u & 0b11000000 == 0b10000000
    }

    private var maxCodeLength: Int { 6 }

    public func next() -> (Int, Character)? {
        let start = offset
        if start >= count || (iterEndOffset != nil && start >= iterEndOffset!)
            || isNotStartCode(data[start])
        {
            return nil
        }
        var end = start + 1
        var validEnd = end == count || data[end] & 0b10000000 == 0
        if !validEnd {
            for _ in 0..<maxCodeLength {
                if end == count - 1 || isStartCode(data[end]) {
                    validEnd = true
                    break
                }
                end += 1
            }
        }
        if !validEnd {
            return nil
        }
        offset = end
        return (start, String(bytes: data[start..<end], encoding: encoding)!.first!)
    }
}

public class StringCharsSequence: SeekableBase, CharsSequence {
    public subscript(range: Range<Int>) -> String? {
        String(
            content[
                content.index(
                    content.startIndex, offsetBy: range.lowerBound)..<content.index(
                        content.startIndex, offsetBy: range.upperBound)])
    }

    public func next() -> (Int, Character)? {
        let start = offset
        if start < count {
            let ch = content[content.index(content.startIndex, offsetBy: start)]
            offset += 1
            return (start, ch)
        }
        return nil
    }

    public typealias Element = (Int, Character)
    private let content: String
    public var count: Int {
        content.count
    }
    public init(_ content: String) {
        self.content = content
    }

}
