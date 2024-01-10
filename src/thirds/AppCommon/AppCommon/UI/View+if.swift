//
//  View+if.swift
//  AppCommon
//
//  Created by zxq on 2023/10/21.
//

import Foundation
import SwiftUI

extension View {
    /// Modifiers can change the components tree, then recreate components.
    /// Used only when view will be reset on condition changed
    @ViewBuilder
    @inlinable public func `if`<IfC: View>(
        _ condition: LiteralOnlyBool, @ViewBuilder then: @escaping (Self) -> IfC
    )
        -> some View
    {
        if condition%! {
            then(self)
        } else {
            self
        }
    }

    /// Modifiers can change the components tree, then recreate components.
    /// Used only when view will be reset on condition changed
    @ViewBuilder
    @inlinable public func `if`<IfC: View, ElseC: View>(
        _ condition: LiteralOnlyBool, @ViewBuilder then: @escaping (Self) -> IfC,
        @ViewBuilder `else`: @escaping (Self) -> ElseC
    )
        -> some View
    {
        if condition%! {
            then(self)
        } else {
            `else`(self)
        }
    }
}
