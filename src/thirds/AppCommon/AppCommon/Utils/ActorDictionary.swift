//
//  ActorDictionary.swift
//  AppCommon
//
//  Created by zxq on 2023/11/25.
//

import Foundation

public actor ActorDictionary<Index: Hashable, Data> {
    private var dict: [Index: Data] = [:]
    public func get(_ index: Index) -> Data? {
        dict[index]
    }
    public func set(_ index: Index, _ newValue: Data) {
        dict[index] = newValue
    }
}
