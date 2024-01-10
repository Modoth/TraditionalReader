//
//  PageSliderV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/11.
//

import Foundation
import SwiftUI

struct SliderV: View {
    @Binding var value: Double?
    @State private var displayValue: Double = 0
    let onSliding: (Double) -> Void
    var body: some View {
        GeometryReader { proxy in
            let length = max(0, proxy.size.width * (value ?? displayValue))
            VStack {
                Spacer().frame(minHeight: 0)
                ZStack {
                    RoundedRectangle(cornerRadius: proxy.size.height).fill(
                        .foreground.opacity(0.25))
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: proxy.size.height).fill(
                            .foreground.opacity(1)
                        )
                        .frame(width: length)
                        Spacer().frame(minWidth: 0)
                    }
                }.frame(height: proxy.size.height / 2)
                Spacer().frame(minHeight: 0)
            }
            ZStack {
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: proxy.size.height).fill(.black.opacity(0))
                        .frame(
                            width: min(
                                proxy.size.width - proxy.size.height,
                                max(0, length - proxy.size.height / 2)))
                    Circle().fill(.background).shadow(radius: 5).gesture(
                        DragGesture().onChanged { e in
                            let dx = e.location.x - e.startLocation.x
                            let displayValue = min(
                                1, max(0, (value ?? displayValue) + dx / proxy.size.width))
                            value = nil
                            self.displayValue = displayValue
                            onSliding(displayValue)
                        }
                    ).fixedSize()
                    Spacer().frame(minWidth: 0)
                }
            }
        }.frame(height: 10)
    }
}

#Preview {
    var v: Double? = 0.50
    return SliderV(value: Binding(get: { v }, set: { v = $0 })) { d in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            v = d + 0.1
        }
    }
    .padding()
}
