//
//  AppConfig.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/24.
//

import AppCommon
import Foundation

private let assetsBookmarkKey = "assetsbookmark"

func getUserSelectedAssetsUrl() -> URL? {
    guard let data = UserDefaults.standard.data(forKey: assetsBookmarkKey) else {
        return nil
    }
    var isStale = false
    guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
        UserDefaults.standard.removeObject(forKey: assetsBookmarkKey)
        return nil
    }
    if isStale {
        guard let data = try? url.bookmarkData() else {
            return nil
        }
        UserDefaults.standard.setValue(data, forKey: assetsBookmarkKey)
    }
    return url
}

func setUserSelectedAssetsUrl(_ url: URL?, _ oldUrl: URL?) throws {
    if let oldUrl = oldUrl {
        oldUrl.stopAccessingSecurityScopedResource()
    }
    guard let url = url else {
        UserDefaults.standard.removeObject(forKey: assetsBookmarkKey)
        return
    }
    let success = url.startAccessingSecurityScopedResource()
    if !success {
        throw BusinessError(.failed)
    }
    guard let data = try? url.bookmarkData() else {
        throw BusinessError(.failed)
    }
    UserDefaults.standard.setValue(data, forKey: assetsBookmarkKey)
}
