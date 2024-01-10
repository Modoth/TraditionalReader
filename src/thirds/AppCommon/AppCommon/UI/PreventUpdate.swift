//
//  PreventUpdate.swift
//  AppCommon
//
//  Created by zxq on 2023/10/25.
//

import Foundation
import SwiftUI

extension Equatable {
    fileprivate func equalTo(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return other.equalTo_(self)
        }
        return self == other
    }

    private func equalTo_(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

extension Array where Element == (any Equatable)? {
    fileprivate func elementEqualTo(_ other: [(any Equatable)?]) -> Bool {
        if self.count != other.count {
            return false
        }
        for i in 0..<self.count {
            let l = self[i]
            let r = other[i]
            if l == nil && r == nil {
                continue
            }
            if l != nil && r != nil {
                if !l!.equalTo(r!) {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
}

public struct PreventUpdate<ID, Content>: View, Equatable
where ID: Hashable, Content: View {
    public static func == (
        lhs: PreventUpdate<ID, Content>, rhs: PreventUpdate<ID, Content>
    )
        -> Bool
    {
        lhs.idBy == rhs.idBy && lhs.bys.elementEqualTo(rhs.bys)
    }

    private let bys: [(any Equatable)?]
    private let idBy: ID?
    private let idChanged: (() -> Void)?
    private let content: () -> Content
    public init(
        _ bys: (any Equatable)?...,
        idBy: ID? = 0,
        idChanged: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.bys = bys
        self.idBy = idBy
        self.idChanged = idChanged
        self.content = content
    }

    public init(
        _ bys: [(any Equatable)?]?,
        idBy: ID? = 0,
        idChanged: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.bys = bys ?? []
        self.idBy = idBy
        self.idChanged = idChanged
        self.content = content
    }

    public var body: some View {
        if idBy != nil {
            content().id(idBy).onAppear(perform: idChanged)
        } else {
            HStack {}.onAppear(perform: idChanged)
        }
    }
}
