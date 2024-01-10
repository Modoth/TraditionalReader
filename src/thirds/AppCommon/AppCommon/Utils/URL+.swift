//
//  URL+.swift
//  AppCommon
//
//  Created by zxq on 2023/11/18.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    public func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }

    public func existedOrNil() -> URL? {
        if FileManager.default.fileExists(atPath: self.relativePath) {
            return self
        }
        return nil
    }
}
