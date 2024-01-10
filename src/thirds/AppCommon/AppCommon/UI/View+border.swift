//
//  View+border.swift
//  AppCommon
//
//  Created by zxq on 2023/9/27.
//

import Foundation
import SwiftUI

extension View {
    @inlinable public func border(_ color: Color, width: CGFloat, edges: [Edge]) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

public struct EdgeBorder: Shape {
    let width: CGFloat
    let edges: [Edge]

    public init(width: CGFloat, edges: [Edge]) {
        self.width = width
        self.edges = edges
    }

    public func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top:
                return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:
                return Path(
                    .init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing:
                return Path(
                    .init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}
