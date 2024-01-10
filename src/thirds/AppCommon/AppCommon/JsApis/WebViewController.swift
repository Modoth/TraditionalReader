//
//  WebViewController.swift
//  AppCommon
//
//  Created by zxq on 2023/11/19.
//

import Foundation
import WebKit

class WebViewController: NSObject, WKScriptMessageHandler {
    weak var parent: WKWebView?
    let jsApisService: JsApisService
    init(parent: WKWebView, jsApiHandler: JsApisService) {
        self.parent = parent
        self.jsApisService = jsApiHandler
    }
    func userContentController(
        _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        if message.name != JS_API_MESSAGE_NAME {
            return
        }
        let body = message.body as! [String: Any]
        let info = JsApiParameter(
            id: body["id"] as! Int, api: body["api"] as! String, method: body["method"] as! String,
            parameters: body["parameters"] as! [Any])
        var js = ""
        do {
            let result = jsApisService.invoke(info: info)
            if result.value == nil {
                js = "window.oshelper?.finishTask(\(info.id), \(result.success))"
            } else {
                js =
                    "window.oshelper?.finishTask(\(info.id), \(result.success), \(String(data: try JSONEncoder().encode(result.value!), encoding: .utf8)!))"
            }
        } catch {
            js = "window.oshelper?.finishTask(\(info.id), false)"
        }
        parent?.evaluateJavaScript(js)
    }
}
