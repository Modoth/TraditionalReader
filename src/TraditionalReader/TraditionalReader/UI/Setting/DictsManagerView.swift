//
//  DictsManagerView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/23.
//

import AppCommon
import SwiftUI

struct DictsManagerView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @EnvironmentObject var dictsService: DictsService
    var body: some View {
        List {
            Section("User") {
                ForEach(dictsService.userDicts, id: \.id) { dict in
                    Text(dict.name)
                }.onDelete(perform: { indexSet in

                })
            }
            Section("Builtin") {
                ForEach(dictsService.builtinDicts, id: \.id) { dict in
                    Text(dict.name)
                }
            }
        }.listStyle(.plain)
    }
}

#Preview {
    ComponentPreview {
        DictsManagerView()
    }.usePreviewServices()
}
