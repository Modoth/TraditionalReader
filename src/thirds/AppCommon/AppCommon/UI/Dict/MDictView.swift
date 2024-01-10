//
//  MDictView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

private struct JsMdxApi: PjsApi {
    static let Api_Name = "mdx"
    static let Command_Query = "query"
    let query: (String?) -> Void
    func invoke(info: AppCommon.JsApiParameter) -> AppCommon.JsApiResult {
        switch info.method {
        case Self.Command_Query:
            let word = info.parameters.first as? String
            query(word)
            return AppCommon.JsApiResult.Successed
        default:
            return AppCommon.JsApiResult.Failed
        }
    }
    static func jsApiName(_ apiName: String) -> String {
        "window.os.\(JsMdxApi.Api_Name)?.\(apiName)"
    }
}

struct MDictView: View {
    @ObservedObject var model: DictModel
    @Binding var key: String?
    @State var currentKey: String? = nil
    @State var content: String? = ""
    var body: some View {
        HStack {
            if let key = (currentKey ?? key)?.first?.lowercased() {
                if model.loaded == true {
                    VStack {
                        if let content = content {
                            WebContentView(
                                content, schema: "mdict", loadResources: model.get(resource:),
                                apisService: JsApisService(apis: [
                                    JsMdxApi.Api_Name: JsMdxApi(query: { query in
                                        DispatchQueue.main.async {
                                            currentKey = query
                                        }
                                    })
                                ]))
                        } else {
                            Text("Not Found")
                        }
                    }.task {
                        content = await model.get(
                            item: key,
                            options: ["jumpKeyFunc": JsMdxApi.jsApiName(JsMdxApi.Command_Query)])
                    }.id(currentKey)
                } else {
                    Text("Loading ...")
                }
            }
        }.overlay {
            if currentKey != nil {
                VStack {
                    HStack {
                        Button(
                            action: {
                                currentKey = nil
                            },
                            label: {
                                Image(systemName: "xmark")
                            }
                        ).buttonStyle(.bordered)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onPropertyChange(of: key) { _ in
            currentKey = nil
        }
        .onPropertyChange(of: currentKey) { _ in
            content = ""
        }
        .task {
            await model.load()
        }
    }
}
