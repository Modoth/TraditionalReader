//
//  ServiceLocatorTests.swift
//  AppCommonTests
//
//  Created by zxq on 2023/9/20.
//

import XCTest

@testable import AppCommon

protocol DummyServiceAP: Service {
    func doSomethingA()
}

protocol DummyServiceBP: Service {
    func doSomethingB()
}

final class ServiceLocatorTests: XCTestCase {
    var servicesCount = 0

    class TestServiceA: DummyServiceAP {
        let container: ServiceLocatorTests
        init(_ container: ServiceLocatorTests) {
            self.container = container
            container.servicesCount += 1
        }
        func doSomethingA() {
        }

        deinit {
            container.servicesCount -= 1
            print("\(Self.self): \(#function)!")
        }
    }

    class TestServiceB: TestServiceA, DummyServiceBP {
        func doSomethingB() {
            let a: TestServiceA = locate()
            a.doSomethingA()
        }
    }

    func test_locator() throws {
        let locator = createServicesContainer {
            $0.register { UUIDRepositoryBase<File>() as any UUIDRepository<File> }
        }.build()
        let s1: (any UUIDRepository<File>) = locator.locate()
        let s2: (any Repository<File>) = locator.locate()
        XCTAssert(s1 != nil)
        XCTAssert(s2 != nil)
    }

    func doSomethingWithLocator() {
        let locator = createServicesContainer {
            $0.register { TestServiceA(self) }
            $0.register { TestServiceA(self) as any DummyServiceAP }
            $0.register { TestServiceB(self) }
            $0.register(lifetime: .transient) { TestServiceB(self) as any DummyServiceBP }
        }.build()
        let s1: TestServiceA = locator.locate()
        s1.doSomethingA()
        let s2: any DummyServiceAP = locator.locate()
        s2.doSomethingA()
        let s3 = TestServiceA(self)
        s3.doSomethingA()
        let s4: TestServiceB = locator.locate()
        s4.doSomethingB()
        let s5: any DummyServiceBP = locator.locate()
        s5.doSomethingB()
        let s6: any DummyServiceBP = locator.locate()
        s6.doSomethingB()
    }

    func test_serviceLifetime() throws {
        doSomethingWithLocator()
        XCTAssert(servicesCount == 0)
    }
}
