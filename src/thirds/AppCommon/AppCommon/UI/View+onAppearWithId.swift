//
//  View+onAppearWithId.swift
//  AppCommon
//
//  Created by zxq on 2023/10/27.
//

import Foundation
import SwiftUI

extension View {
    /// Perform action when id changed
    @inlinable public func onAppearWithId<ID>(_ id: ID, perform action: (() -> Void)? = nil)
        -> some View
    where ID: Hashable {
        self.onAppear(perform: action).id(id)
    }
}
