//
//  ReadingBook+.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/25.
//

import Foundation

extension ReadingBook {
    var thumb: String {
        let totalThumbs = 4
        return "readinglist\(abs(self.id.hashValue) % totalThumbs)"
    }
}
