//
//  WebView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/4.
//

import Foundation
import SwiftUI
import WebKit

public struct WebView: UIViewRepresentable {
    public let url: URL?
    public init(url: URL?) {
        self.url = url
    }
    public func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    public func updateUIView(_ webView: WKWebView, context: Context) {
        if url != nil {
            let request = URLRequest(url: url!)
            webView.load(request)
        }
    }
}

#Preview {
    WebView(url: nil)
}
