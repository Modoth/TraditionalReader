//
//  TraditionalReaderApp.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/18.
//

import AppCommon
import SwiftUI
import WCDBSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    @Published var url: URL? = nil
    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let urlContext = connectionOptions.urlContexts.first {
            url = urlContext.url
        }
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        url = URLContexts.first?.url
    }
}

@main
struct TraditionalReaderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(OO(sharedLocator))
                .setNotifyService()
                #if DEBUG
                    .onAppear {
                        print(Bundle.main.bundlePath)
                    }
                #endif
        }
    }
}
