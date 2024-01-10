//
//  DictItem.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/15.
//

import Foundation

public protocol DictParser {
    func parse(_ file: URL, _ dicFile: DictFile) throws -> (
        info: [String: String],
        sections: [DictSection],
        items: [DictItem]
    )
    func getItemBlock(_ item: DictItem, _ section: DictSection, in buffer: [UInt8]) throws
        -> [UInt8]
    func decodeSection(_ section: DictSection, url: URL) throws -> [UInt8]
}
