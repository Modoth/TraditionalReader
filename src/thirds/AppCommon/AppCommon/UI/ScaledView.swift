//
//  ScaledView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/12.
//

import Foundation
import SwiftUI

public struct ScaledView<Content: View>: View {
    let scale: Double
    let aspectRatio: Double
    let content: () -> Content
    public init(scale: Double, aspectRatio: Double, content: @escaping () -> Content) {
        self.scale = scale
        self.aspectRatio = aspectRatio
        self.content = content
    }
    public var body: some View {
        Rectangle().fill(.transparent).aspectRatio(aspectRatio, contentMode: .fit).contentShape(
            Rectangle()
        )
        .overlay {
            GeometryReader { proxy in
                content().frame(
                    width: proxy.size.width / scale, height: proxy.size.height / scale
                )
                .scaleEffect(scale, anchor: .topLeading)
                .allowsHitTesting(false)
            }
        }
    }
}
