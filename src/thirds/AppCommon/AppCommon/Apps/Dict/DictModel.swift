//
//  DictModel.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI
import WCDBSwift

public class DictModel: BackgroundLoadableBase<Bool>, ObservableObject, Identifiable, Equatable,
    Service
{
    public static func == (lhs: DictModel, rhs: DictModel) -> Bool {
        lhs.id == rhs.id
    }

    private var _type: String? = nil
    private var _namespace: String? = nil
    private var _name: String? = nil
    private var _url: URL? = nil
    public var type: String { _type! }
    public var namespace: String { _namespace! }
    public var name: String { _name! }
    public var url: URL { _url! }

    public lazy var parser: any DictParser = {
        locate(group: type)
    }()

    public func view(_ key: Binding<String?>) -> AnyView {
        fatalError("Not implemented.")
    }
    public func `init`(type: String, namespace: String, at url: URL) -> Self {
        self._type = type
        self._namespace = namespace
        self._url = url
        self._name = url.deletingPathExtension().lastPathComponent
        return self
    }

    func modifyContent(content: String, options: [String: String]?) -> String {
        fatalError("Not implemented.")
    }

    func getResourceKey(resource path: URL) -> [String] {
        fatalError("Not implemented.")
    }

    func getDictFiles() -> [URL] {
        fatalError("Not implemented.")
    }

    func fileQuickHash(_ namespace: String, _ url: URL) -> UInt64 {
        let attr = try? FileManager.default.attributesOfItem(
            atPath: url.path(percentEncoded: false))
        return (namespace + url.lastPathComponent).simpleHash()
            &+ (attr?[FileAttributeKey.size] as? UInt64 ?? 0)
    }

    var dic: Dict? = nil
    var dictFiles: [UUID: URL] = [:]
    var dictInfo: [String: String] = [:]

    public override func loading() -> Loaded {
        let drep: any UUIDRepository<Dict> = locate()
        dic = try! drep.read$(by: .fileName, value: self.url.lastPathComponent).filter {
            $0.namespace == namespace
        }.first
        if dic == nil {
            dic = Dict()
                .with(\.id, UUID())
                .with(\.namespace, namespace)
                .with(\.fileName, self.url.lastPathComponent)
            try! drep.create(dic!)
        }

        let frep: any UUIDRepository<DictFile> = locate()
        let fileUrls = getDictFiles()
        var addingFiles: [URL] = []
        let files = try! frep.read$(by: .dict, value: dic!.id)
        let filesMap = Dictionary(uniqueKeysWithValues: files.map { ($0.fileName, $0) })
        var deletingFiles = filesMap
        for url in fileUrls {
            guard let file = filesMap[url.lastPathComponent] else {
                addingFiles.append(url)
                continue
            }
            if !file.finished || file.hash != fileQuickHash(namespace, url) {
                try! frep.delete(file)
                addingFiles.append(url)
                continue
            }
            deletingFiles[url.lastPathComponent] = nil
            dictFiles[file.id] = url
            if file.fileName == dic!.fileName {
                dictInfo = file.info
            }
        }
        for (_, file) in deletingFiles {
            try! frep.delete(file)
        }

        for url in addingFiles {
            let file = DictFile()
                .with(\.id, UUID())
                .with(\.dict, dic!.id)
                .with(\.fileName, url.lastPathComponent)
                .with(\.hash, fileQuickHash(namespace, url))
            try! frep.create(file)
            let parsed = try! parser.parse(url, file)
            file.info = parsed.info
            if file.fileName == dic!.fileName {
                dictInfo = file.info
            }
            try! frep.update(file, bys: [.info])
            if !parsed.sections.isEmpty {
                let srep: any UUIDRepository<DictSection> = locate()
                try! srep.create(parsed.sections)
            }

            if !parsed.items.isEmpty {
                let irep: any UUIDRepository<DictItem> = locate()
                try! irep.create(parsed.items)
            }

            file.finished = true
            try! frep.update(file, bys: [.finished])
            dictFiles[file.id] = url
        }
        return true
    }

    func getItemBuffer(_ value: String, byKey: Bool = false) async -> [UInt8]? {
        let rep: any UUIDRepository<DictItem> = locate()
        let srep: any UUIDRepository<DictSection> = locate()
        guard
            let item = byKey
                ? (try? rep.readOne(
                    where: DictItem.Properties.key == value && DictItem.Properties.dict == dic!.id))
                : (try? rep.readOne(
                    where: DictItem.Properties.title == value && DictItem.Properties.dict == dic!.id
                )),
            let section = try? srep.readOne(by: .id, value: item.section),
            let fileUrl = dictFiles[section.file]
        else {
            return nil
        }
        guard let sectionBuffer = try? await decodeSection(section, url: fileUrl) else {
            return nil
        }
        guard let buffer = try? parser.getItemBlock(item, section, in: sectionBuffer) else {
            return nil
        }
        return buffer
    }

    func decodeSection(_ section: DictSection, url: URL) async throws -> [UInt8] {
        guard let cache = await sectionCaches.get(section.id) else {
            let task = Task(priority: .utility) {
                try parser.decodeSection(section, url: url)
            }
            let cache = try await task.value
            await self.sectionCaches.set(section.id, cache)
            return cache
        }
        return cache
    }

    var sectionCaches = ActorDictionary<UUID, [UInt8]>()

    func normalizeEncoding(_ str: String?) -> String.Encoding {
        switch str?.lowercased() {
        case "utf-16":
            return .utf16LittleEndian
        default:
            return .utf8
        }
    }

    public func get(item key: String, options: [String: String]?) async -> String? {
        guard let buffer = await getItemBuffer(key),
            let content = String(bytes: buffer, encoding: normalizeEncoding(dictInfo["Encoding"]))
        else {
            return nil
        }
        return modifyContent(content: content, options: options)
    }

    public func get(resource path: URL) async -> (String, Data)? {
        for key in getResourceKey(resource: path) {
            guard let key = key.removingPercentEncoding,
                let data = await getItemBuffer(key, byKey: true)
            else {
                return nil
            }
            let mime = path.mimeType()
            return (mime, Data(bytes: data, count: data.count))
        }
        return nil
    }
}
