//
//  ReadingList+.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/31.
//

import Foundation

extension ReadingList {
    var thumb: String {
        let totalThumbs = 4
        return "readinglist\(abs((self.name).hash) % totalThumbs)"
    }
}
