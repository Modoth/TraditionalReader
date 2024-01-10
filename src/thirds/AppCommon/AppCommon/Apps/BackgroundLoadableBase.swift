//
//  BackgroundLoadableBase.swift
//  AppCommon
//
//  Created by zxq on 2023/11/23.
//

import Foundation

open class BackgroundLoadableBase<Loaded> {
    public init() {}
    public typealias Loaded = Loaded
    @Published public var loaded = false
    public var loadingTask: Task<Void, Never>? = nil
    public func load(priority: TaskPriority = .background) async {
        if loaded {
            return
        }
        if let loadingTask = loadingTask {
            await loadingTask.value
            return
        }
        loadingTask = Task(priority: priority) {
            let result = loading()
            DispatchQueue.main.sync {
                onLoad(result)
                loaded = true
            }
            loadingTask = nil
        }
        await loadingTask!.value
    }

    open func loading() -> Loaded {
        fatalError("Not implemented.")
    }

    open func onLoad(_ result: Loaded) {

    }
}
