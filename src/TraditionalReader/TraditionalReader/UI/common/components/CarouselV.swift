//
//  CarouselV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/21.
//

import Foundation
import SwiftUI

struct CarouselV<Data, Content, ID>: View
where
    Data: RandomAccessCollection, ID: Hashable, Content: View
{
    let items: Data
    let content: (Data.Element) -> Content
    let scale: Double
    let id: KeyPath<Data.Element, ID>

    @State private var currentPage: Int = 0
    @State private var current: Data.Element? = nil

    var body: some View {
        let _ = Self._printTrace()
        let size = UIScreen.main.bounds
        ZStack {
            ScrollViewReader { s in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(items, id: id) { item in
                            HStack {
                                content(item).padding([.leading, .vertical])
                            }.id(item[keyPath: id]).frame(width: size.width * scale)
                        }
                    }.padding([.trailing])
                }.scrollDisabled(scale >= 1)
                    .gesture(
                        DragGesture().onEnded({ value in
                            let dir = Int(
                                (value.location.x - value.startLocation.x) * 10 / size.width)
                            if abs(dir) < 1 {
                                return
                            }
                            var page = currentPage + (dir > 0 ? -1 : 1)
                            page = min(items.count - 1, max(0, page))
                            let item = items[items.index(items.startIndex, offsetBy: page)]
                            withAnimation(.easeInOut) {
                                s.scrollTo(item[keyPath: id], anchor: .leading)
                                current = item
                                currentPage = page
                            }
                        })
                    )
            }
            if scale >= 1 && items.count > 1 {
                VStack {
                    Spacer()
                    HStack {
                        ForEach(items, id: id) { item in
                            Rectangle().fill(.primary.opacity(0.5)).frame(
                                width: item[keyPath: id] == current?[keyPath: id] ? 12 : 4,
                                height: 4
                            ).cornerRadius(4)
                        }
                    }
                }
            }
        }.onAppear {
            current = items.first
        }
    }
}

extension CarouselV where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ items: Data, scale: Double = 0.8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.items = items
        self.content = content
        self.scale = scale
        self.id = \Data.Element.id
        self.current = items.first
        self.currentPage = 0
    }
}

extension CarouselV {
    init(
        _ items: Data, id: KeyPath<Data.Element, ID>, scale: Double = 0.8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.items = items
        self.id = id
        self.content = content
        self.scale = scale
        self.current = items.first
        self.currentPage = 0
    }
}

#Preview {
    CarouselV([Int](repeating: 0, count: 5).map { _ in ReadingBook.mock() }, id: \ReadingBook.id) {
        book in
        ReadingBookDetailView(
            book
        ).background(.white).lightShadow()
    }.usePreviewServices()
}
