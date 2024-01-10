//
//  print.swift
//  AppCommon
//
//  Created by zxq on 2023/9/21.
//

import Foundation

#if DEBUG
    @inline(__always) public func debugprint(
        _ items: Any..., separator: String = " ", terminator: String = "\n"
    ) {
        Swift.print(items, separator: separator, terminator: terminator)
    }
#else
    @inline(__always)
    public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    }
    @inline(__always)
    public func debugprint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    }
#endif
