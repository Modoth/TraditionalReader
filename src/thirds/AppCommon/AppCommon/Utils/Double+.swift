//
//  Double+.swift
//  AppCommon
//
//  Created by zxq on 2023/11/13.
//

import Foundation

extension Double {
    @inlinable
    public var d$: Double {
        (self > 1 || self < -1) ? self.truncatingRemainder(dividingBy: 1) : self
    }
}
