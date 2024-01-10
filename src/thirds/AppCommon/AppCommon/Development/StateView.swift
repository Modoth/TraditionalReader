//
//  StateView.swift
//  AppCommon
//
//  Created by zxq on 2023/11/7.
//

import Foundation
import SwiftUI

public struct StateView<StateModel, Content>: View
where Content: View, StateModel: ObservableObject {
    let view: (StateModel) -> Content
    @ObservedObject var state: StateModel
    public init(_ state: StateModel, @ViewBuilder view: @escaping (StateModel) -> Content) {
        self.view = view
        self.state = state
    }

    @ViewBuilder
    public var body: some View {
        view(state)
    }
}
