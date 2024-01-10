//
//  OSHelper.swift
//  WebTools
//
//  Created by 周雪芹 on 2022/7/27.
//

import Foundation

extension JsApisService {
    func getInjectedCode(maxTid: Int, jsTaskHandlerName: String) -> String {
        """
        // communication with os
        (() => {
        const oshelper = (() => {
        const tasks = new Map()
        const maxTid = \(maxTid)
        const getUsableTid = () => {
            for (let i = 0; i < maxTid; i++) {
                if (tasks.has(i)) {
                    continue
                }
                return i
            }
            return undefined
        }
        const setTask = (id, task) => tasks.set(id, task)
        const deleteTask = (id) => tasks.delete(id)
        const finishTask = (id, success, result) => {
            const task = tasks.get(id)
            deleteTask(id)
            if (success) {
                task.resolve(result)
            } else {
                task.reject(result)
            }
        }
        return { getUsableTid, setTask, deleteTask, finishTask }
        })();
        const os = new Proxy({}, {
        get: (_, api) => new Proxy({}, {
            get: (_, method) => (...parameters) => {
                const id = oshelper.getUsableTid()
                if (id === undefined) {
                    return Promise.reject()
                }
                const task = {}
                oshelper.setTask(id, task)
                try {
                    const msg = {
                        id,
                        api,
                        method,
                        parameters //:parameters.map(s => JSON.stringify(s))
                    }
                    window.webkit.messageHandlers.\(jsTaskHandlerName).postMessage(msg)
                    const result = new Promise((resolve, reject) => {
                        task.resolve = resolve
                        task.reject = reject
                    })
                    return result
                } catch {
                    oshelper.deleteTask(id)
                    return Promise.reject()
                }
            }
        })
        })
        window.os = os
        window.oshelper = {finishTask: oshelper.finishTask}
        })();
        """
    }
}
