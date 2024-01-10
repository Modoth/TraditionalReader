//
//  JsApiHandler.swift
//  WebTools
//
//  Created by 周雪芹 on 2022/7/28.
//

import CoreData
import Foundation

public struct JsApisService {
    let apis: [String: PjsApi]

    public init(apis: [String: PjsApi]) {
        self.apis = apis
    }

    func invoke(info: JsApiParameter) -> JsApiResult {
        guard let h = apis[info.api] else {
            return .Failed
        }
        return h.invoke(info: info)
    }
}
