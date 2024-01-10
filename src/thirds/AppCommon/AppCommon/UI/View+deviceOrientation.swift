//
//  View+deviceOrientation.swift
//  AppCommon
//
//  Created by zxq on 2023/11/2.
//

import Foundation
import SwiftUI

struct DetectOrientation: ViewModifier {
    @Binding var orientation: UIDeviceOrientation
    func body(content: Content) -> some View {
        content
            .onReceive(
                NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            ) { _ in
                orientation = UIDevice.current.orientation
            }
    }
}

extension View {
    public func deviceOrientation(_ orientation: Binding<UIDeviceOrientation>) -> some View {
        modifier(DetectOrientation(orientation: orientation))
    }
}
