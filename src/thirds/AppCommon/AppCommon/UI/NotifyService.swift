//
//  NotifyService.swift
//  AppCommon
//
//  Created by zxq on 2023/9/22.
//

import Foundation
import SwiftUI

public class NotifyService: ObservableObject {
    @Published var toastMessage: LocalizedStringKey? = nil
    private var version = Date.now
    public func toast(msg: LocalizedStringKey, timeout: Int = 500) {
        DispatchQueue.main.sync {
            self.toastMessage = msg
            let version = Date.now
            self.version = version
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(timeout) / 1000.0,
                execute: {
                    if version == self.version {
                        self.toastMessage = nil
                    }
                })
        }
    }
}

private struct NotifyServiceModifier: ViewModifier {
    @ObservedObject fileprivate var notifyService = NotifyService()

    private var screen: CGRect {
        #if os(iOS)
            return UIScreen.main.bounds
        #else
            return NSScreen.main?.frame ?? .zero
        #endif
    }

    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if let toastMessage = notifyService.toastMessage {
                    HStack {
                        Spacer()
                        Text(toastMessage).padding().foregroundColor(.white)
                        Spacer()
                    }
                    .background(.primary)
                    .padding()
                    .shadow(radius: 5)
                    .frame(maxWidth: screen.width, maxHeight: screen.height, alignment: .top)
                    .animation(.easeInOut, value: notifyService.toastMessage)
                }
            }
        ).environmentObject(notifyService)
    }
}

extension View {
    public func setNotifyService() -> some View {
        modifier(NotifyServiceModifier())
    }
}
