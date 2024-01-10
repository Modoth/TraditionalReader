//
//  FontsServiceTests.swift
//  TraditionalReaderTests
//
//  Created by zxq on 2023/11/22.
//

import SwiftUI
import XCTest

@testable import AppCommon
@testable import TraditionalReader

final class FontsServiceTests: TestCaseBase {
    override func setUpWithError() throws {
        register.register { FileResourceManagerConfig(root: self.tmpDataUrl) }
        register.register(factory: FileResourceManager$)
    }

    func getAllFonts() -> [(familyName: String, fontNames: [String])] {
        return UIFont.familyNames.map({ familyName in
            let fontNames = UIFont.fontNames(forFamilyName: familyName)
            return (familyName, fontNames)
        })
    }

    func testExample() throws {
        let fonts = getAllFonts()
        print(fonts)
        let f = UIFont.preferredFont(forTextStyle: .body).fontName

        let font = CTFont(f as CFString, size: 14)
        let utf16 = Array("我".utf16)
        var gs = [CGGlyph](repeating: 0, count: utf16.count)
        if CTFontGetGlyphsForCharacters(font, utf16, &gs, utf16.count) {
            //            glyphs[str] = (false, nil)
        } else {
            //            glyphs[str] = (true, gs[0])
        }
        let folderURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        folderURL.appendingPathComponent("fonts")
        //        let folderURL2 = try FileManager.default.url(
        //                    for: .documentDirectory,
        //                    in: .systemDomainMask,
        //                    appropriateFor: nil,
        //                    create: false
        //                )
        let url = Bundle(for: DictsServiceImpl.self).path(
            forResource: "fonts/TW-Kai-Plus", ofType: "ttf")!
        let provider = CGDataProvider(filename: url)!
        let cgFont = CGFont(provider)!
        let name = cgFont.postScriptName as! String
        print(cgFont)
    }
}
