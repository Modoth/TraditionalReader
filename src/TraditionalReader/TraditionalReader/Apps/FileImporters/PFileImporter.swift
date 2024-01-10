//
//  PFileImporter.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/19.
//

import Foundation

protocol FileImporterP {
    func importFile(_ url: URL, context: FileImporterContext, on: ((FileImporterEvent) -> Void)?)
}

struct FileImporterContext {
    let pwd: String?
    let interruptOnError: Bool = false
}

struct FileImporterTaskInfo {
    let idx: Int64
    let total: Int64
    let name: String
    let type: String
}

enum FileImporterError {
    case unsupported
    case cancled
    case unknown
}

enum FileImporterEvent {
    case start(file: FileImporterTaskInfo)
    case finish(file: FileImporterTaskInfo)
    case failed(file: FileImporterTaskInfo, error: FileImporterError)
}
