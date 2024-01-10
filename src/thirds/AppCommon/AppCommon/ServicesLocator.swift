//
//  ServiceLocator.swift
//  AppCommon
//
//  Created by zxq on 2023/9/19.
//

import Foundation

public protocol ServicesLocator {
    func tryLocate(serviceName: String, group: String?) -> AnyObject?
}

extension ServicesLocator {
    @inlinable public func locate(serviceName: String, group: String? = nil) -> AnyObject {
        let service = tryLocate(serviceName: serviceName, group: group)
        precondition(service != nil)
        return service!
    }

    @inlinable public func tryLocate<T>(group: String) -> T? {
        return tryLocate(serviceName: "\(T.self)", group: group) as? T
    }

    @inlinable public func locate<T>(group: String? = nil) -> T {
        let service: T? = tryLocate(serviceName: "\(T.self)", group: group) as? T
        precondition(service != nil)
        return service!
    }
}

public protocol DelegatedServicesLocator: ServicesLocator {
    var locator: ServicesLocator { get }
}

extension DelegatedServicesLocator {
    public func tryLocate(serviceName: String, group: String? = nil) -> AnyObject? {
        return locator.tryLocate(serviceName: serviceName, group: group)
    }
}

public protocol Service: DelegatedServicesLocator, AnyObject {

}

extension Service {
    public var locator: ServicesLocator {
        ServicesLocatorImpl.serviceLocators[ObjectIdentifier(self)]!.value
    }
}

public enum ServiceLifetime {
    case singleton
    case transient
}

public protocol ServicesContainer {
    func registerService(
        serviceName: String,
        lifetime: ServiceLifetime, group: String?, factory: @escaping () -> AnyObject
    )
    func build() -> ServicesLocator
}

public func createServicesContainer(registerTo: ((ServicesContainer) -> Void)? = nil)
    -> ServicesContainer
{
    let container = ServicesLocatorImpl()
    if registerTo != nil {
        registerTo!(container)
    }
    return container
}

extension ServicesContainer {
    @inlinable public func register<T>(
        lifetime: ServiceLifetime = .singleton, group: String? = nil, factory: @escaping () -> T
    ) {
        self.registerService(
            serviceName: "\(T.self)", lifetime: lifetime, group: group,
            factory: { factory() as AnyObject })
    }
}

private class ServicesLocatorImpl: ServicesLocator, ServicesContainer {

    class ServiceLocatorUnownedBox {
        unowned let value: ServicesLocatorImpl
        init(_ value: ServicesLocatorImpl) {
            self.value = value
        }
    }

    static var serviceLocators: [ObjectIdentifier: ServiceLocatorUnownedBox] = [:]

    func build() -> ServicesLocator {
        return self
    }

    func registerService(
        serviceName: String,
        lifetime: ServiceLifetime = .singleton, group: String? = nil,
        factory: @escaping () -> AnyObject
    ) {
        precondition(!frozened, "Register after frozen.")
        let key = getTypeKey(serviceName, group)
        assertUnregistered(key)
        factories[key] = (lifetime, factory)
    }

    func tryLocate(serviceName: String, group: String? = nil) -> AnyObject? {
        frozened = true
        let key = getTypeKey(serviceName, group)
        if services[key] != nil {
            return services[key]
        }
        if factories[key] == nil {
            return nil
        }
        let (lifetime, factory) = factories[key]!

        switch lifetime {
        case .singleton:
            return getSingletonService(key, factory)
        case .transient:
            let service = factory()
            Self.serviceLocators[ObjectIdentifier(service)] = ServiceLocatorUnownedBox(self)
            return service
        }
    }

    private var frozened = false
    private let lock = NSLock()
    private var services: [String: AnyObject] = [:]
    private var factories: [String: (ServiceLifetime, () -> AnyObject)] = [:]

    private static let invalidTypeName = "\((any DummyGenericProtocol<Int>).self)"

    private func getTypeKey(_ key: String, _ group: String? = nil) -> String {
        precondition(key != Self.invalidTypeName)
        return key + (group == nil ? "" : (" _ " + group!))
    }

    private func assertUnregistered(_ key: String) {
        #if DEBUG
            services[key] = nil
            factories[key] = nil
        #else
            precondition(services[key] == nil && factories[key] == nil)
        #endif
    }

    private func getSingletonService(_ key: String, _ factory: () -> AnyObject) -> AnyObject? {
        if services[key] == nil {
            lock.lock()
            defer {
                lock.unlock()
            }
            if services[key] == nil {
                let service = factory()
                Self.serviceLocators[ObjectIdentifier(service)] = ServiceLocatorUnownedBox(self)
                services[key] = service
            }
        }
        return services[key]
    }
}

private protocol DummyGenericProtocol<TItem> {
    associatedtype TItem
}
