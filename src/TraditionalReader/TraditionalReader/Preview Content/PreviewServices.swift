//
//  PreviewServices.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/13.
//

import AppCommon
import Foundation
import SwiftUI
import WCDBSwift

extension ReadingPanelType: RandMockable {

}

extension ReadingPanelSize: RandMockable {

}

private let FileResourceManager$1: () -> any FileResourceManager = {
    class Imp: FileResourceManager {
        func url(id: UUID, resource: String?) -> URL {
            (Bundle.main.resourceURL?.appending(components: "previewdata", "荀子.txt"))!
        }
        func delete(id: UUID, resource: String?) throws {}
        func copy(fromUrl: URL, toId: UUID, resource: String) throws {}
    }
    return Imp() as any FileResourceManager
}

extension View {
    public func usePreviewServices(registerTo: ((ServicesContainer) -> Void)? = nil) -> some View {
        let locator = OO(createLocator())
        let s = locator%! as! ServicesContainer
        s.register {
            Database(at: "")  // Prevent db access
        }
        s.register(factory: FileResourceManager$1)
        s.register(factory: MockRepository$1(File.default))
        s.register(factory: MockRepository$1(ReadingList.default))
        s.register(factory: MockRepository$1(ReadingBook.default))
        s.register(factory: MockRepository$1(ReadingPanel.default))
        s.register(factory: MockRepository$1(Dict.default))
        s.register(factory: MockRepository$1(DictFile.default))
        s.register(factory: MockRepository$1(DictSection.default))
        s.register(factory: MockRepository$1(DictItem.default))
        registerTo?(s)
        return self.setNotifyService()
            .useEnvironmentServices(locator.value)
            .environmentObject(locator)
    }
}
