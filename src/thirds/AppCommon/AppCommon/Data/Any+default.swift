//
//  Any+default.swift
//  AppCommon
//
//  Created by zxq on 2023/10/22.
//

import Foundation

private let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
extension UUID {
    public static var zero: UUID {
        defaultUUID
    }
    public static var `default`: UUID {
        defaultUUID
    }
}

private let defaultString = ""
extension String {
    public static var `default`: String {
        defaultString
    }
}

private let defaultDate = Date(timeIntervalSince1970: 0)
extension Date {
    public static var `default`: Date {
        defaultDate
    }
}

private let defaultBool = false
extension Bool {
    public static var `default`: Bool {
        defaultBool
    }
}

private let defaultInt: Int = 0
extension Int {
    public static var `default`: Int {
        defaultInt
    }
}

private let defaultUInt64: UInt64 = 0
extension UInt64 {
    public static var `default`: UInt64 {
        defaultUInt64
    }
}

private let defaultUInt: UInt32 = 0
extension UInt32 {
    public static var `default`: UInt32 {
        defaultUInt
    }
}

private let defaultUInt8: UInt8 = 0
extension UInt8 {
    public static var `default`: UInt8 {
        defaultUInt8
    }
}

private let defaultDouble: Double = 0
extension Double {
    public static var `default`: Double {
        defaultDouble
    }
}
