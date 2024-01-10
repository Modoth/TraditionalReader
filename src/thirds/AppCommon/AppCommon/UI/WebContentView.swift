//
//  WebContentView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/17.
//

import SwiftUI
import WebKit

public class LocalContentURLSchemeHandler: NSObject, WKURLSchemeHandler {
    let urlSchema: String
    let loadResources: (URL) async -> (mimeType: String, data: Data)?
    init(
        _ urlSchema: String? = nil,
        _ loadResources: @escaping (URL) async -> (mimeType: String, data: Data)?
    ) {
        self.urlSchema = urlSchema ?? "localcontent"
        self.loadResources = loadResources
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            return
        }
        Task { [weak self, weak urlSchemeTask] in
            //            try? await Task.sleep(for: .seconds(3))
            let res = await self?.loadResources(url)
            DispatchQueue.main.sync {
                guard let urlSchemeTask = urlSchemeTask else {
                    return
                }
                guard let (mimeType, data) = res else {
                    print("Request Failed: \(url.absoluteString)")
                    urlSchemeTask.didReceive(HTTPURLResponse())
                    urlSchemeTask.didFinish()
                    return
                }
                let response = HTTPURLResponse(
                    url: url,
                    mimeType: mimeType,
                    expectedContentLength: data.count, textEncodingName: nil)
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
        }
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }
}

public class FontsService {
    static let singleton = FontsService()
    let urlSchema = "localfont"
    let fontNames: [(name: String, path: String, mimeType: String)]
    init() {
        let fm = FileManager.default
        var fontNames: [(name: String, path: String, mimeType: String)] = []
        for path
            in (try? fm.contentsOfDirectory(
                atPath: Bundle.main.path(forResource: "fonts", ofType: nil)!)) ?? []
        {
            let url = Bundle.main.url(forResource: "fonts/\(path)", withExtension: nil)!
            fontNames.append(
                (
                    url.deletingPathExtension().lastPathComponent, "\(urlSchema):///\(path)",
                    url.mimeType()
                ))
        }
        self.fontNames = fontNames
    }

    func loadResources(_ url: URL) -> (mimeType: String, data: Data)? {
        guard
            let fileUrl = Bundle.main.url(
                forResource: "fonts/\(url.relativePath)", withExtension: nil),
            let data = try? Data(contentsOf: fileUrl)
        else {
            return nil
        }
        return (fileUrl.mimeType(), data)
    }

    private var _css: String? = nil
    var css: String {
        if _css == nil {
            _css =
                "<style>\n"
                + fontNames.map { font in
                    "@font-face\n{\n\tfont-family: \"\(font.name)\";\n\tsrc:url(\"\(font.path)\");\n}"
                }.joined(separator: "\n") + "\n</style>"
        }
        return _css!
    }
}

public struct WebContentView: UIViewRepresentable {
    let dictServices = FontsService.singleton
    let html: String
    let schema: String?
    let loadResources: ((URL) async -> (mimeType: String, data: Data)?)?
    let apisService: JsApisService?
    public init(
        _ html: String, schema: String? = nil,
        loadResources: ((URL) async -> (mimeType: String, data: Data)?)? = nil,
        apisService: JsApisService? = nil
    ) {
        self.html = dictServices.css + html
        self.schema = schema
        self.loadResources = loadResources
        self.apisService = apisService
    }
    public func makeUIView(context: Context) -> WKWebView {
        guard let loadResources = loadResources else {
            return WKWebView()
        }
        let preferences = WKPreferences()

        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        let dictHandler = LocalContentURLSchemeHandler(schema, loadResources)
        configuration.setURLSchemeHandler(dictHandler, forURLScheme: dictHandler.urlSchema)
        configuration.setURLSchemeHandler(
            LocalContentURLSchemeHandler(dictServices.urlSchema, dictServices.loadResources),
            forURLScheme: dictServices.urlSchema)
        if let apisService = apisService {
            let userContent = WKUserContentController()
            let script = WKUserScript.init(
                source: apisService.getInjectedCode(
                    maxTid: 1000, jsTaskHandlerName: JS_API_MESSAGE_NAME),
                injectionTime: .atDocumentStart, forMainFrameOnly: true)
            userContent.addUserScript(script)
            configuration.userContentController = userContent
        }
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.bounces = false

        if let apisService = apisService {
            let contentController = WebViewController(parent: webView, jsApiHandler: apisService)
            webView.configuration.userContentController.add(
                contentController, name: JS_API_MESSAGE_NAME)
        }

        return webView
    }
    public func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: schema == nil ? nil : URL(string: "\(schema!)://"))
    }
}

//public class WebViewV : WKWebView {
//    override public func loadSimulatedRequest(_ request: URLRequest, responseHTML string: String) -> WKNavigation {
//
//    }
//}

#Preview {
    let js = ""
    let css = ""
    let content = "hello, world"
    return WebContentView(
        """
        <html>
          <meta charset="utf-8" />
          <base href="dict:///" />
          <meta
            name="viewport"
            content="width=device-width, maximum-scale=1.0,user-scalable=no, initial-scale=1"
          />
          <script>\(js)</script>
          <style rel="stylesheet" href="./a.css">\(css)</style>
          <body>
            \(content)
          </body>
        </html>
        """)
}
