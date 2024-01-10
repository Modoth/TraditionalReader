//
//  DictsView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

public struct DictsView: ViewBase {
    @EnvironmentObject public var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject public var notifyServices: NotifyService
    @EnvironmentObject private var dictssService: DictsService

    @Binding private var key: String?
    @State private var current: DictModel? = nil

    public init(key: Binding<String?>) {
        _key = key
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(dictssService.dicts, id: \.id) { dict in
                    Text(dict.name).foregroundStyle(
                        (dict.id == current?.id) ? .primary : .secondary
                    ).onTapGesture {
                        current = dict
                    }
                    Spacer()
                }
            }.padding(.vertical, 10).padding(.horizontal)
                .lightBorder(edges: [.bottom])
            ZStack {
                ForEach(dictssService.dicts, id: \.id) { dict in
                    PreventUpdate(dict.id) {
                        dict.view($key)
                    }
                    .opacity((dict.id == current?.id) ? 1 : 0)
                }
            }.padding([.horizontal, .bottom], 10)
        }.onAppear {
            current = dictssService.dicts.first
        }.onPropertyChange(of: dictssService.dicts) { value in
            current = current ?? dictssService.dicts.first
        }
    }
}
