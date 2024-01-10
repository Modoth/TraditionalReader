//
//  AssetsManagerConfigView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/24.
//

import AppCommon
import SwiftUI

struct AssetsManagerConfigView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var fontsService: FontsService
    @EnvironmentObject var dictsService: DictsService

    @State private var presentingSelectFolder = false
    var body: some View {
        let (defaultUrl, selectedUrl) = fontsService.getUserDir()
        HStack {
            Image(systemName: "folder").frame(width: 18)
            Text("External Assets Directory")
            Spacer()
            if let selectedUrl = selectedUrl {
                Text(selectedUrl.lastPathComponent).foregroundStyle(.secondary)
            }
        }.contentShape(Rectangle())
            .onTapGesture {
                presentingSelectFolder = true
            }
            .fileImporter(isPresented: $presentingSelectFolder, allowedContentTypes: [.folder]) {
                v in
                guard case let .success(url) = v else {
                    return
                }
                if url == selectedUrl {
                    return
                }
                let newSelectedUrl =
                    (url == defaultUrl
                        || ("/private" + defaultUrl.relativePath == url.relativePath)) ? nil : url
                guard let _ = try? setUserSelectedAssetsUrl(newSelectedUrl, selectedUrl) else {
                    return
                }
                fontsService.setUserDir(newSelectedUrl)
                dictsService.setUserDir(newSelectedUrl)
            }
    }
}

#Preview {
    ComponentPreview {
        AssetsManagerConfigView()
    }.usePreviewServices()
}
