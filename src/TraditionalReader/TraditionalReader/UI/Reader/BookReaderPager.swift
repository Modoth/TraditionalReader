//
//  BookReaderPager.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/31.
//

import Foundation

struct BookReaderPager {
    let width: Int?
    let height: Int?
    let getPageForInitPosition:
        (Int, Bool, Int?, @escaping (Int, Range<Int>, Range<Int>, Bool) -> Void) -> UUID?
    let getPositionForPage: (Int, @escaping (Range<Int>) -> Void) -> UUID?
    let getMinPage: (@escaping (Int) -> Void) -> UUID?
    let getMaxPage: (@escaping (Int) -> Void) -> UUID?
    let unregisterEvent: (UUID) -> Void
    let shared: AnyObject?
}
