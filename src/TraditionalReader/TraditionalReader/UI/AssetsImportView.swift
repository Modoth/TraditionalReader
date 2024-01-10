//
//  AssetsImportView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/22.
//

import AppCommon
import SwiftUI

struct AssetsImportView: ViewBase {
    @EnvironmentObject var sceneDelegate: SceneDelegate
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var fontsService: FontsService

    var body: some View {
        if let url = sceneDelegate.url {
            if let (_, f) = getImporter(url) {
                HStack {}.alert(
                    "Import: \(url.lastPathComponent)", isPresented: .constant(true)
                ) {
                    Button(
                        "Cancle",
                        action: {
                            sceneDelegate.url = nil
                        })
                    Button(
                        "OK",
                        action: {
                            if let url = sceneDelegate.url {
                                sceneDelegate.url = nil
                                Task {
                                    if url.startAccessingSecurityScopedResource() {
                                        defer {
                                            url.stopAccessingSecurityScopedResource()
                                        }
                                        await tryDoAsync {
                                            try await f(url)
                                        }
                                    } else {
                                        throw BusinessError(.failed)
                                    }
                                }
                            }
                        })
                }
            } else {
                HStack {}.alert("Unsupported file type", isPresented: .constant(true)) {
                    Button(
                        "OK",
                        action: {
                            sceneDelegate.url = nil
                        })
                }
            }
        }
    }

    private func getImporter(_ url: URL) -> (
        type: LocalizedStringKey, f: (URL) async throws -> Void
    )? {
        let type = url.pathExtension.lowercased()
        switch type {
        case "txt", "pdf":
            return ("Book", importBook)
        case "ttf":
            return ("Font", { try await fontsService.importFont($0) })
        default:
            return nil
        }
    }

    private func importBook(_ url: URL) throws {
        let filesService: FilesService = locate()
        let book = try filesService.import(url: url, in: nil)
    }
}
