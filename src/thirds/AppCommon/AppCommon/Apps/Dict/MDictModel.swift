//
//  MDictModel.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

public let MdictModel$ = { MdictModel() as DictModel }

private class MdictModel: DictModel {
    private var stylesheets: [String: (String, String)] = [:]
    private var css: String = ""
    private var js: String = ""

    override func view(_ key: Binding<String?>) -> AnyView {
        AnyView(
            MDictView(model: self, key: key)
        )
    }

    override func getDictFiles() -> [URL] {
        let baseUrl = url.deletingLastPathComponent()
        var mddUrls: [URL] = []
        if let mddUrl = baseUrl.appending(path: "\(name).mdd").existedOrNil() {
            mddUrls.append(mddUrl)
            var i = 1
            while let mddUrl = baseUrl.appending(path: "\(name).\(i).mdd").existedOrNil() {
                i += 1
                mddUrls.append(mddUrl)
            }
        }
        return [url] + mddUrls
    }

    override func loading() -> Loaded {
        let _ = super.loading()
        let baseUrl = url.deletingLastPathComponent()
        if let cssUrl = baseUrl.appending(path: "\(name).css").existedOrNil() {
            css = (try? String(contentsOf: cssUrl)) ?? ""
        }
        if let jsUrl = baseUrl.appending(path: "\(name).js").existedOrNil() {
            js = (try? String(contentsOf: jsUrl)) ?? ""
        }
        let styleSheetStr = dictInfo["StyleSheet"] ?? ""
        if styleSheetStr != "" {
            let reg = /(?:^|\n)(\d+)\n/
            let styles = styleSheetStr.split(separator: reg).map {
                let tokens = $0.split(separator: "\n")
                let first = tokens.count > 0 ? String(tokens[0]).unescapeXml() : ""
                let second = tokens.count > 1 ? String(tokens[1]).unescapeXml() : ""
                return (first, second)
            }
            let ids = styleSheetStr.matches(of: reg).map { String($0.output.1) }
            stylesheets = Dictionary(zip(ids, styles)) { $1 }
        }
        return true
    }

    override func modifyContent(content: String, options: [String: String]?) -> String {
        var content = content
        if let jumpKeyFunc = options?["jumpKeyFunc"] {
            content = content.replacing(/@@@LINK=(\S+)/) { m in
                let key = m.output.1
                return "@@@LINK=<a onclick=\"\(jumpKeyFunc)('\(key)')\">\(key)</a>"
            }
        }
        if stylesheets.count > 0 {
            let reg = /`(\d+)`/
            let tokens = content.split(separator: reg, omittingEmptySubsequences: false).map {
                String($0)
            }
            let ids = [""] + content.matches(of: reg).map { String($0.output.1) }
            content = (0..<max(tokens.count, ids.count)).map { i in
                guard let style = stylesheets[ids[i]] else {
                    return tokens[i]
                }
                return style.0 + tokens[i] + style.1
            }.joined()
        }
        return formatHtml(content)
    }

    override func getResourceKey(resource path: URL) -> [String] {
        let key = path.relativePath
        let formattedKey = key.replacingOccurrences(of: "/", with: "\\")
        return [formattedKey, key]
    }

    private func formatHtml(_ content: String) -> String {
        return """
            <html>
              <meta charset="utf-8" />
              <meta
                name="viewport"
                content="width=device-width, maximum-scale=1.0,user-scalable=no, initial-scale=1"
              />
              <script>\(js)</script>
              <style rel="stylesheet">\(css)</style>
              <body>
                \(content)
              </body>
            </html>
            """
    }
}
