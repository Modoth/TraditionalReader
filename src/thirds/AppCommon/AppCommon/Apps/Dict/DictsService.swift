//
//  DictsService.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation
import SwiftUI

public class DictsService: BackgroundLoadableBase<
    (builtinDicts: [DictModel], userDicts: [DictModel])
>,
ObservableObject
{
    @Published public var builtinDicts: [DictModel] = []
    @Published public var userDicts: [DictModel] = []
    @Published public var dicts: [DictModel] = []
    public func setUserDir(_ url: URL?) {
        fatalError("Not implemented.")
    }
    public func getUserDir() -> (URL, URL?) {
        fatalError("Not implemented.")
    }
}

public class DictsServiceConfig {
    public init(builtinDir: URL, userDir: URL, userSelectedDir: URL?, types: [String]) {
        self.builtinDir = builtinDir
        self.userDir = userDir
        self.userSelectedDir = userSelectedDir
        self.types = Set(types)
    }
    fileprivate let builtinDir: URL
    fileprivate let userDir: URL
    fileprivate let types: Set<String>
    fileprivate var userSelectedDir: URL?
    fileprivate var userActualDir: URL {
        userSelectedDir ?? userDir
    }
}

public let DictsService$ = { DictsServiceImpl() as DictsService }

class DictsServiceImpl: DictsService, Service {
    private lazy var config: DictsServiceConfig = { locate() }()

    override func setUserDir(_ url: URL?) {
        config.userSelectedDir = url
        builtinDicts = []
        userDicts = []
        dicts = []
        loaded = false
        if loadingTask != nil {
            loadingTask!.cancel()
        }
        Task(priority: .background) {
            await self.load()
        }
    }

    override func getUserDir() -> (URL, URL?) {
        (config.userDir, config.userSelectedDir)
    }

    override func loading() -> Loaded {
        let builtinDicts = getDicts(namespace: "builtin", in: config.builtinDir)
        let userDicts = getDicts(namespace: "user", in: config.userActualDir)
        return (builtinDicts, userDicts)
    }

    override func onLoad(_ result: Loaded) {
        self.builtinDicts = result.builtinDicts
        self.userDicts = result.userDicts
        self.dicts = result.userDicts + result.builtinDicts
    }

    private func getDicts(namespace: String, in url: URL) -> [DictModel] {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil)
        else {
            return []
        }
        return urls.map { getDict(namespace: namespace, at: $0) }.notNils()
    }

    private func getDict(namespace: String, at url: URL) -> (DictModel)? {
        let type = url.pathExtension.lowercased()
        if config.types.contains(type) {
            let dict: DictModel = locate(group: type)
            return dict.`init`(type: type, namespace: namespace, at: url)
        }
        return nil
    }
}
