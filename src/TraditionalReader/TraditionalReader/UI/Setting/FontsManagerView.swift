//
//  FontsManagerView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/21.
//

import AppCommon
import SwiftUI

struct FontsManagerView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var fontsService: FontsService
    var body: some View {
        List {
            Section("User") {
                ForEach(fontsService.userFonts, id: \.self) { font in
                    Text(font.name)
                }.onDelete(perform: { indexSet in

                })
            }
            Section("Builtin") {
                ForEach(fontsService.builtinFonts, id: \.self) { font in
                    Text(font.name)
                }
            }
        }.listStyle(.plain)
    }
}

#Preview {
    ComponentPreview {
        FontsManagerView()
    }.usePreviewServices()
}
