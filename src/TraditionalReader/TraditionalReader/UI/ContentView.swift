//
//  ContentView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/18.
//

import AppCommon
import SwiftUI
import WCDBSwift

struct ContentView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService
    @SceneStorage("AppScreen") var selection: AppScreen = .reading
    @State var dataUpdated = false

    var body: some View {
        let _ = Self._printTrace()
        if dataUpdated {
            TabView(selection: $selection) {
                Group {
                    ForEach(AppScreen.allCases) { screen in
                        screen.destination
                            .tag(screen as AppScreen?)
                            .tabItem { screen.label }
                    }
                }
            }.overlay {
                AssetsImportView()
            }
            .useEnvironmentServices(servicesLocator.value)
        } else {
            HStack {}.onAppear(perform: {
                do {
                    tryDo {
                        try updateData(servicesLocator%!)
                        dataUpdated = true
                    }
                }
            })
        }
    }
}

#Preview {
    ContentView().usePreviewServices()
}
