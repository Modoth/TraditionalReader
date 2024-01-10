//
//  ZDictView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

struct ZDictView: View {
    @ObservedObject var model: DictModel
    @Binding var key: String?
    @State var currentKey: String? = nil
    @State var content: String? = nil
    var body: some View {
        HStack {
            if let key = (currentKey ?? key)?.first?.lowercased() {
                if model.loaded == true {
                    VStack {
                        if let content = content {
                            WebContentView(
                                content, schema: "mdict", loadResources: model.get(resource:),
                                apisService: JsApisService(apis: [:]))
                        } else {
                            Text("Not Found")
                        }
                    }.id(currentKey).task {
                        content = await model.get(item: key, options: nil)
                    }
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
