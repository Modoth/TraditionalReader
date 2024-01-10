//
//  String+.swift
//  AppCommon
//
//  Created by zxq on 2023/11/7.
//

import CryptoKit
import Foundation

extension String {
    public init?(contentsOf url: URL, offset: Int, count: Int, encoding: String.Encoding = .utf8) {
        guard let data = try? LazyData<Int>(contentsOf: url) else {
            return nil
        }
        self.init()
        let maxPos = min(Int(UInt32.max), data.count)
        let end = offset > (maxPos - count) ? maxPos : (offset + count)
        let start = end >= count ? (end - count) : 0
        var endI = end
        var startI = start
        var validStart = false
        if startI != endI {
            for _ in 0..<4 {
                if data[startI] & 0b11000000 == 0b10000000 {
                    startI += 1
                    if startI == endI {
                        break
                    }
                    continue
                }
                validStart = true
                break
            }
        }
        if !validStart {
            return nil
        }
        var validEnd = endI == maxPos
        if !validEnd {
            for _ in 0..<4 {
                if data[endI] & 0b11000000 == 0b10000000 {
                    endI += 1
                    if endI == maxPos {
                        validEnd = true
                        break
                    }
                    continue
                }
                validEnd = true
                break
            }
        }
        if !validEnd {
            return nil
        }
        guard let str = String(bytes: data[startI..<endI], encoding: .utf8) else {
            return nil
        }
        self = str
    }
}

private let unescapeXmlMap: [String: String] = [
    "&amp;": "&",
    "&quot;": "\"",
    "&#x27;": "'",
    "&#39;": "'",
    "&#x92;": "'",
    "&#x96;": "-",
    "&gt;": ">",
    "&lt;": "<",
]
extension String {
    public func unescapeXml() -> String {
        var res = self
        for (k, v) in unescapeXmlMap {
            res = res.replacingOccurrences(of: k, with: v)
        }
        return res
    }
}

extension String {
    /// From internet
    public func simpleHash() -> UInt64 {
        var hash: UInt64 = 5381
        for c in self.data(using: .utf8)! {
            hash = ((hash << 5) &+ hash) &+ UInt64(c)
        }
        return hash
    }
}
