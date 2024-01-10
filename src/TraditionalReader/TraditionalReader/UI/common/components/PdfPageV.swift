//
//  PdfPageV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/24.
//

import Foundation
import PDFKit
import SwiftUI

struct PdfPageV: UIViewRepresentable {

    let doc: PDFDocument
    let page: Int
    init(doc: PDFDocument, page: Int = 0) {
        self.doc = doc
        self.page = page
    }

    func makeUIView(context: Context) -> UIView {
        let pdfView = PDFView()
        pdfView.document = doc
        pdfView.displayDirection = .horizontal
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.pageShadowsEnabled = false
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let pdfView = uiView as! PDFView
        let page = pdfView.document!.page(at: self.page)!
        pdfView.go(to: page)
    }
}

#Preview {
    PdfPageV(
        doc: PDFDocument(
            url: (Bundle.main.resourceURL?.appending(components: "previewdata", "荀子.pdf"))!)!,
        page: 2)
}
