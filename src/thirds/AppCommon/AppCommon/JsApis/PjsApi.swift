//
//  PjsApi.swift
//  WebTools
//
//  Created by 周雪芹 on 2022/7/28.
//

import CoreData
import Foundation

public protocol PjsApi {
    func invoke(info: JsApiParameter) -> JsApiResult
}
