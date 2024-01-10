//
//  View+.swift
//  AppCommon
//
//  Created by zxq on 2023/9/22.
//

import Foundation
import SwiftUI

extension View {
    @inlinable public func useServices(registerTo: @escaping (ServicesContainer) -> Void)
        -> some View
    {
        self.environmentObject(
            OO(
                createServicesContainer(registerTo: registerTo).build()))
    }
}
