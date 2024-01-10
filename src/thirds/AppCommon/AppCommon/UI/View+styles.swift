//
//  View+styles.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import SwiftUI

extension View {
    public func lightBorder(edges: [Edge] = [.bottom]) -> some View {
        border(.black.opacity(0.1), width: 1, edges: edges)
    }

    public func lighterBorder(edges: [Edge] = [.bottom]) -> some View {
        border(.black.opacity(0.05), width: 1, edges: edges)
    }
}

extension View {
    @inlinable public func lightShadow() -> some View {
        shadow(color: .black.opacity(0.1), radius: 5)
    }
}
