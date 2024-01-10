//
//  ZDictModel.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

public let ZdictModel$ = { ZdictModel() as DictModel }

private class ZdictModel: DictModel {
    override func view(_ key: Binding<String?>) -> AnyView {
        AnyView(
            ZDictView(model: self, key: key)
        )
    }

    override func getDictFiles() -> [URL] {
        return [url]
    }

    override func modifyContent(content: String, options: [String: String]?) -> String {
        return content
    }

    override func getResourceKey(resource path: URL) -> [String] {
        let key = path.relativePath
        let formattedKey = key.replacing(/^\/-\//, with: "")
        return [formattedKey, key]
    }
}
