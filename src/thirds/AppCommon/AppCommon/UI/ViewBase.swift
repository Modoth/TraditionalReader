//
//  View+Base.swift
//  AppCommon
//
//  Created by zxq on 2023/9/25.
//

import Foundation
import SwiftUI

public protocol ComponentBase: View, DelegatedServicesLocator {
    var servicesLocator: OO<ServicesLocator> { get }
}

extension ComponentBase {
    public var locator: ServicesLocator {
        servicesLocator%!
    }
}

public protocol ViewBase: ComponentBase, DelegatedServicesLocator {
    var notifyServices: NotifyService { get }
}

public protocol UpdatableView: View {
    var updateBys: [(any Equatable)?]? { get }
    var forceUpdateBy: ForceUpdateBy? { get }
    associatedtype UpdatableBody: View
    associatedtype ForceUpdateBy: Hashable = Int
    @ViewBuilder var updatableBody: Self.UpdatableBody { get }
}

extension UpdatableView {
    public var body: some View {
        PreventUpdate(updateBys) {
            updatableBody
        }
    }
    public var updateBys: [(any Equatable)?]? { nil }
    public var forceUpdateBy: ForceUpdateBy? { nil }
}

public protocol UpdatableComponentBase: ComponentBase, UpdatableView {

}

public protocol UpdatableViewBase: ViewBase, UpdatableView {

}

extension ViewBase {
    public func tryDo(
        success: LocalizedStringKey? = nil, failed: LocalizedStringKey = "",
        _ action: () throws -> Void
    ) {
        do {
            try action()
            if success != nil {
                notifyServices.toast(msg: success!)
            }
        } catch let error as BusinessError {
            #if !DEBUG
                precondition(error.type != .fatalError)
            #endif
            notifyServices.toast(msg: error.type.stringKey)
        } catch (let error) {
            print("\(error)")
            notifyServices.toast(msg: failed)
        }
    }

    public func tryDoAsync(
        success: LocalizedStringKey? = nil, failed: LocalizedStringKey = "",
        _ action: () async throws -> Void
    ) async {
        do {
            try await action()
            if success != nil {
                notifyServices.toast(msg: success!)
            }
        } catch let error as BusinessError {
            #if !DEBUG
                precondition(error.type != .fatalError)
            #endif
            notifyServices.toast(msg: error.type.stringKey)
        } catch (let error) {
            print("\(error)")
            notifyServices.toast(msg: failed)
        }
    }
}
