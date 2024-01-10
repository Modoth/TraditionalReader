//
//  View+safeAreaPadding.swift
//  AppCommon
//
//  Created by zxq on 2023/11/2.
//

import Foundation
import SwiftUI

@frozen
public struct SafeAreaPaddingModifier: ViewModifier {
    public var edgeInsets: EdgeInsets

    @inlinable
    public init(_ edgeInsets: EdgeInsets) {
        self.edgeInsets = edgeInsets
    }

    @inlinable
    public init(_ length: CGFloat = 16) {
        self.init(EdgeInsets(top: length, leading: length, bottom: length, trailing: length))
    }

    @inlinable
    public init(_ edges: Edge.Set, _ length: CGFloat = 16) {
        let edgeInsets = EdgeInsets(
            top: edges.contains(.top) ? length : 0,
            leading: edges.contains(.leading) ? length : 0,
            bottom: edges.contains(.bottom) ? length : 0,
            trailing: edges.contains(.trailing) ? length : 0
        )
        self.init(edgeInsets)
    }

    public func body(content: Content) -> some View {
        content
            ._safeAreaInsets(edgeInsets)
    }
}

extension View {
    @inlinable
    public func safeAreaPaddings(_ edgeInsets: EdgeInsets) -> some View {
        self.modifier(SafeAreaPaddingModifier(edgeInsets))
    }

    @inlinable
    public func safeAreaPaddings(_ length: CGFloat = 16) -> some View {
        self.modifier(SafeAreaPaddingModifier(length))
    }

    @inlinable
    public func safeAreaPaddings(_ edges: Edge.Set, _ length: CGFloat = 16) -> some View {
        self.modifier(SafeAreaPaddingModifier(edges, length))
    }
}
