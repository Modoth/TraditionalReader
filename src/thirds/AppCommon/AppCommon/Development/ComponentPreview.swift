//
//  ComponentPreview.swift
//  AppCommon
//
//  Created by zxq on 2023/10/26.
//

import Foundation
import SwiftUI

public struct ComponentPreview<Content>: View where Content: View {
    class DataWraper<Data>: Identifiable {
        let value: Data
        init(_ value: Data) {
            self.value = value
        }
    }
    let view: () -> Content
    let count: Int

    public init(_ count: Int = 1, @ViewBuilder view: @escaping () -> Content) {
        self.view = view
        self.count = count
    }

    @State var datas: [DataWraper<Int>] = []

    @ViewBuilder
    public var body: some View {
        VStack {
            Button("Refresh", action: generateDatas)
            VStack {
                ForEach(datas) { _ in
                    view()
                }
            }
        }.onAppear(perform: generateDatas)
    }

    private func generateDatas() {
        let idx = Array(repeating: 0, count: count)
        datas = idx.enumerated().map { (_, i) in DataWraper(i) }
    }
}
