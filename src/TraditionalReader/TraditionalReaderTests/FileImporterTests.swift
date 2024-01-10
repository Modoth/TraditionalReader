//
//  FileImporterTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/9/19.
//

import AppCommon
import XCTest

@testable import TraditionalReader

final class FileImporterTests: XCTestCase {

    func testExample() throws {
        //        let path =
        //            "/Users/zxq/Library/Developer/CoreSimulator/Devices/0A7A3F00-1AF2-42C7-B3F3-358E65B7C543/data/Containers/Shared/AppGroup/86E9F92E-3DF0-495C-825F-227EAD9177BD/File%20Provider%20Storage/%E8%AF%9A%E6%96%8B%E6%98%93%E4%BC%A0_%E5%89%AF%E6%9C%AC.txt"
        //        let locator = ServiceLocator.createSingleton()
        //        locator.register {
        //            BooksRepository() as any BooksRepositoryP
        //        }
        //        locator.register(group: "txt") {
        //            TextFileImporter() as FileImporterP
        //        }
        //
        //        let importer = FileImporter()
        //        let url = URL(string: path)
        //        importer.importFile(url!, context: FileImporterContext(), on: nil)
    }

    func test_LargeFile() throws {
        let path = Bundle(for: Self.self).url(forResource: "data/large.txt", withExtension: nil)!
        let chars = try FileCharsSequence(path)
        for apro in (0..<2).map({ _ in (0..<chars.count).randomElement()! }) {
            guard let range = chars.search("\n", latestBefore: apro, maxSearch: nil) else {
                print("\(apro): not found")
                continue
            }
            chars.seek(range.lowerBound)
            for j in 0..<10 {
                guard let (i, c) = chars.next() else {
                    return
                }
                print("\(apro):\(j)=\(i): \(c)")
            }
        }
    }
}
