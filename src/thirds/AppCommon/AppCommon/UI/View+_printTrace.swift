//
//  View+_printTrace.swift
//  AppCommon
//
//  Created by zxq on 2023/10/29.
//

import Foundation
import SwiftUI

extension View {
    @inline(__always) static public func _printTrace() {
        #if DEBUG
            let info = "\(Self.self)"
            //        let types = "!^*-=+."
            let types = "!^*-=+."
            let type = types[
                types.index(types.startIndex, offsetBy: abs(info.hashValue) % types.count)]
            let paddings = String(repeating: type, count: 4)
            print("▪️    \(paddings)[\(info)]\(paddings)")
            Self._printChanges()
        #endif
    }
}
