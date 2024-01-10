//
//  SettingView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/19.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationStack {
            List {
                #if DEBUG
                    Section("Test") {
                        TestView()
                    }
                #endif
                Section("Management") {
                    AssetsManagerConfigView()
                    NavigationLink {
                        FontsManagerView()
                            .navigationTitle("Fonts")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                EditButton()
                            }
                    } label: {
                        Image(systemName: "f.cursive").frame(width: 18)
                        Text("Fonts")
                    }
                    NavigationLink {
                        DictsManagerView()
                            .navigationTitle("Dictionaries")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                EditButton()
                            }
                    } label: {
                        Image(systemName: "d.square").frame(width: 18)
                        Text("Dictionaries")
                    }
                }
            }.navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingView().usePreviewServices()
}
