//
//  IdFileManager.swift
//  AppCommon
//
//  Created by zxq on 2023/9/19.
//

import Foundation

// public protocol with default fileprivate implement
// suit for unit test with ServiceLocatorP/ServiceP
// in **protocol-oriented programming**

// public protocol
public protocol FileResourceManager {
    func url(id: UUID, resource: String?) -> URL
    func delete(id: UUID, resource: String?) throws
    func copy(fromUrl: URL, toId: UUID, resource: String) throws
}

// public extension methods with default arguments and surfixed-name
extension FileResourceManager {
    public func url$(id: UUID, resource: String? = nil) -> URL { url(id: id, resource: resource) }
    public func delete$(id: UUID, resource: String? = nil) throws {
        try delete(id: id, resource: resource)
    }
}

// dependent data with config
public class FileResourceManagerConfig {
    public init(root: URL) {
        self.root = root
    }
    fileprivate let root: URL
}

// export default implement with surfixed name
public let FileResourceManager$ = { FileResourceManagerImpl() as FileResourceManager }

// fileprivate implement
private class FileResourceManagerImpl: FileResourceManager, Service {
    func url(id: UUID, resource: String?) -> URL {
        let idStr = id.uuidString.replacingOccurrences(of: "-", with: "")
        var idx = idStr.startIndex
        let componentLength = 2
        let componentsCount = 4
        var url = base.root
        for _ in 0..<componentsCount {
            let end = idStr.index(idx, offsetBy: componentLength)
            url.append(component: idStr[idx..<end])
            idx = end
        }
        url.append(component: idStr[idx...])
        if resource != nil {
            url.append(component: resource!)
        }
        return url
    }

    func delete(id: UUID, resource: String?) throws {
        let toUrl = url(id: id, resource: resource)
        let fm = FileManager.default
        if fm.fileExists(atPath: toUrl.path()) {
            try fm.removeItem(at: toUrl)
        }
    }

    func copy(fromUrl: URL, toId: UUID, resource: String) throws {
        let toUrl = url(id: toId, resource: resource)
        let fm = FileManager.default
        let toFolder = toUrl.deletingLastPathComponent()
        try fm.createDirectory(at: toFolder, withIntermediateDirectories: true)
        try fm.copyItem(at: fromUrl, to: toUrl)
    }

    private lazy var base: FileResourceManagerConfig = {
        locate()
    }()
}
