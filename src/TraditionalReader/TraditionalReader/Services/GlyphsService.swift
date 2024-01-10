//
//  GlyphsService.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/18.
//

import Foundation
import SwiftUI

class GlyphsService {
    static let singleton = GlyphsService()
    var fontGlyphs: [String: (CTFont?, String?, [String: (Bool, CGGlyph?)])] = [:]
    func get(_ str: String, fonts: [(String, Bool?)]) -> (String, CGGlyph)? {
        return get(str, fonts.map { $0.0 })
    }
    func get(_ str: String, _ fonts: [String]) -> (String, CGGlyph)? {
        for fontName in fonts {
            if fontGlyphs[fontName] == nil {
                guard let url = Bundle.main.path(forResource: "fonts/\(fontName).ttf", ofType: nil),
                    let provider = CGDataProvider.init(filename: url),
                    let cgFont = CGFont.init(provider)
                else {
                    print("No such font: \(fontName)")
                    fontGlyphs[fontName] = (nil, nil, [:])
                    continue
                }

                let font = CTFontCreateWithGraphicsFont(cgFont, 14, nil, nil)
                var error: Unmanaged<CFError>?
                guard CTFontManagerRegisterGraphicsFont(cgFont, &error),
                    let cgFontName = cgFont.postScriptName as? String
                else {
                    print("Register Failed: \(fontName)")
                    fontGlyphs[fontName] = (nil, nil, [:])
                    continue
                }
                fontGlyphs[fontName] = (font, cgFontName, [:])
            }
            var (optFont, cgFontName, glyphs) = fontGlyphs[fontName]!
            guard let font = optFont else {
                return nil
            }

            if glyphs[str] == nil {
                let utf16 = Array(str.utf16)
                var gs = [CGGlyph](repeating: 0, count: utf16.count)
                if !CTFontGetGlyphsForCharacters(font, utf16, &gs, utf16.count) {
                    glyphs[str] = (false, nil)
                } else {
                    glyphs[str] = (true, gs[0])
                }
            }
            let (existed, glyph) = glyphs[str]!
            if existed {
                return (cgFontName!, glyph!)
            }

        }
        print("No such character\(str)")
        return nil
    }
}
