//
//  FileType+.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/31.
//

import AppCommon
import Foundation

extension FileType {
    var view: any FileReaderPageView.Type {
        switch self {
        case .txt:
            TxtReaderPageView.self
        case .pdf:
            PdfReaderPageView.self
        case .none:
            UnsupportedReaderView.self
        }
    }
}
