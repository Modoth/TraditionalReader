//
//  FontsService.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/22.
//

import AppCommon
import Foundation
import SwiftUI

class FontsService: BackgroundLoadableBase<(builtinFonts: [AppFont], userFonts: [AppFont])>,
    ObservableObject
{
    @Published var builtinFonts: [AppFont] = []
    @Published var userFonts: [AppFont] = []
    @discardableResult
    func importFont(_ url: URL) async throws -> AppFont {
        fatalError("Not implemented.")
    }
    public func setUserDir(_ url: URL?) {
        fatalError("Not implemented.")
    }
    public func getUserDir() -> (URL, URL?) {
        fatalError("Not implemented.")
    }
}

class FontsServiceConfig {
    init(builtinDir: URL, userDir: URL, userSelectedDir: URL?) {
        self.builtinDir = builtinDir
        self.userDir = userDir
        self.userSelectedDir = userSelectedDir
    }
    fileprivate let builtinDir: URL
    fileprivate let userDir: URL
    fileprivate var userSelectedDir: URL?
    fileprivate var userActualDir: URL {
        userSelectedDir ?? userDir
    }
}

struct AppFont: Hashable {
    let name: String
    let displayName: String?
    let path: URL?
}

let FontsService$ = { FontsServiceImpl() as FontsService }

extension AppFont {
    init(at url: URL) {
        self.init(name: url.lastPathComponent, displayName: nil, path: url)
    }
}

private class FontsServiceImpl: FontsService, Service {
    private lazy var config: FontsServiceConfig = { locate() }()

    override func setUserDir(_ url: URL?) {
        config.userSelectedDir = url
        builtinFonts = []
        userFonts = []
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
        let systemFonts = getFonts(in: config.builtinDir)
        let userFonts = getFonts(in: config.userActualDir)
        return (systemFonts, userFonts)
    }

    override func onLoad(_ result: Loaded) {
        self.builtinFonts = result.builtinFonts
        self.userFonts = result.userFonts
    }

    override func importFont(_ url: URL) async throws -> AppFont {
        await load()
        let to = config.userActualDir.appending(path: url.lastPathComponent)
        let fm = FileManager.default
        if fm.fileExists(atPath: to.relativePath) {
            throw BusinessError(.fileExisted)
        }
        try FileManager.default.copyItem(at: url, to: to)
        let font = AppFont(at: to)
        userFonts.append(font)
        return font
    }

    private func getFonts(in url: URL) -> [AppFont] {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil)
        else {
            return []
        }
        return urls.filter(isFontUrl).map { AppFont(at: $0) }
    }

    private func isFontUrl(_ url: URL) -> Bool {
        Self.fontExts.contains(url.pathExtension.lowercased())
    }

    private static let fontExts: Set<String> = ["ttf"]
}
