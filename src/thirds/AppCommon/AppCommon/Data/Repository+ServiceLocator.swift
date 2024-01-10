//
//  Repository+ServiceLocator.swift
//  AppCommon
//
//  Created by zxq on 2023/10/28.
//

import Foundation

extension ServicesLocator {
    public func locate<T: UUIDNamedTableCodable>(group: String? = nil) -> any UUIDRepository<T> {
        return locate(serviceName: "\((any Repository).self)<\(T.self)>", group: group)
            as! any UUIDRepository<T>
    }

    public func locate<T: NamedTableCodable>(group: String? = nil) -> any Repository<T> {
        return locate(serviceName: "\((any Repository).self)<\(T.self)>", group: group)
            as! any Repository<T>
    }
}

extension ServicesContainer {
    @inlinable public func register<T: NamedTableCodable>(
        lifetime: ServiceLifetime = .singleton, group: String? = nil,
        factory: @escaping () -> any Repository<T>
    ) {
        self.registerService(
            serviceName: "\((any Repository).self)<\(T.self)>", lifetime: lifetime, group: group,
            factory: { factory() as AnyObject })
    }
}
