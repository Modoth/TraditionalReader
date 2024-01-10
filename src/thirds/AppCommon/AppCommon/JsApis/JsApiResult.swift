//
//  JsApiResult.swift
//  WebTools
//
//  Created by 周雪芹 on 2022/7/28.
//

import Foundation

public struct JsApiResult {
    public static let Successed = JsApiResult(success: true, value: nil)
    public static let Failed = JsApiResult(success: false, value: nil)
    public let success: Bool
    public let value: Encodable?
}
