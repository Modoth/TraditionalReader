//
//  MdxDictParser.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Compression
import Foundation

public let MdxDictParser$ = { MdxDictParser() as any DictParser }

private class MdxDictParser: DictParser {
    func parse(_ file: URL, _ dicFile: DictFile) throws -> (
        info: [String: String], sections: [DictSection], items: [DictItem]
    ) {
        let (_, keys, recBlockInfos, info, _) = try parseKeys(
            file: file, parentInfo: nil)
        let isEntryItem = file.pathExtension.lowercased() == "mdx"
        var sections = recBlockInfos.map { block in
            DictSection()
                .with(\.id, UUID())
                .with(\.file, dicFile.id)
                .with(\.start, block.start)
                .with(\.end, block.start + block.compSize)
                .with(\.metaInfo, 0)
        }

        var items = keys.map { key in
            let item = DictItem()
                .with(\.id, UUID())
                .with(\.dict, dicFile.dict)
                .with(\.key, key.key)
            if isEntryItem {
                item.title = key.key
            }

            guard let section = sections.tryGet(Int(key.blockId)),
                let block = recBlockInfos.tryGet(Int(key.blockId))
            else {
                return nil as (DictItem?)
            }
            item.section = section.id
            item.start = key.blockOffset
            item.end =
                key.blockOffset
                + (key.count != nil ? UInt64(key.count!) : (block.dataEnd - key.offset))
            return item
        }.notNils()

        return (info, sections, items)
    }

    public func getItemBlock(_ item: DictItem, _ section: DictSection, in buffer: [UInt8]) throws
        -> [UInt8]
    {
        let reader = createDataReader(buffer)
        return reader.getBuffer(Int(item.start), count: Int(item.end - item.start))
    }

    public func decodeSection(_ section: DictSection, url: URL) throws -> [UInt8] {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        guard let fileSize = attr[FileAttributeKey.size] as? UInt64 else {
            throw URLError(.cannotOpenFile)
        }
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer {
            try? fileHandle.close()
        }
        try fileHandle.seek(toOffset: section.start)
        let count = Int(section.end - section.start)
        let buffer = try fileHandle.read(upToCount: count)!

        let reader = DataReader([UInt8](buffer))
        return decompAndDecryptBuffer(reader, count)
    }

    public init() {

    }

    func createDataReader<Buffer: BufferSource>(_ data: Buffer) -> DataReader<Buffer> {
        .init(data)
    }

    func decryptBuffer(_ buffer: [UInt8], _ key: [UInt8]) -> [UInt8] {
        var buffer = buffer
        let ripeKey = ripemd128(data: key)
        var prev: UInt8 = 0x36
        for i in 0..<buffer.count {
            var byte = buffer[i]
            byte = ((byte >> 4) | (byte << 4))
            byte = byte ^ prev ^ UInt8((i & 0xFF)) ^ ripeKey[i % ripeKey.count]
            prev = buffer[i]
            buffer[i] = byte
        }
        return buffer
    }

    func inflate(_ encodedSourceData: [UInt8], algorithm: compression_algorithm = COMPRESSION_ZLIB)
        -> [UInt8]
    {
        let decodedCapacity = 8_000_000
        let decodedDestinationBuffer = UnsafeMutablePointer<UInt8>.allocate(
            capacity: decodedCapacity)
        defer {
            decodedDestinationBuffer.deallocate()
        }
        return encodedSourceData[2...].withUnsafeBytes { encodedSourceBuffer in
            let typedPointer = encodedSourceBuffer.bindMemory(to: UInt8.self)
            let decodedCharCount = compression_decode_buffer(
                decodedDestinationBuffer, decodedCapacity,
                typedPointer.baseAddress!, encodedSourceData.count,
                nil,
                algorithm)
            return Array(
                UnsafeBufferPointer(start: decodedDestinationBuffer, count: decodedCharCount))
        }
    }

    func decompAndDecryptBuffer<Buffer>(
        _ reader: DataReader<Buffer>, _ compSize: Int, _ bufferEncrypted: Bool = false
    ) -> [UInt8] {
        var pos = reader.position
        reader.position += Buffer.Index(compSize)
        let compType: UInt32 = reader.get(pos)
        pos += 4
        let checksum = reader.getBuffer(pos, count: 4)
        pos += 4
        if compType != 0 && compType != 2 {
            fatalError("Not implemented")
        }
        var u8s = reader.getBuffer(pos, count: Int(reader.position - pos))
        if bufferEncrypted {
            var key = checksum
            key.append(contentsOf: [0x95, 0x36, 0x00, 0x00])
            u8s = decryptBuffer(u8s, key)
        }
        if compType == 2 {
            u8s = inflate(u8s)
        }
        return u8s
    }

    func readKeyBlockInfos<Buffer: BufferSource>(
        _ buffer: Buffer, _ blockCount: Int, _ codingUnit: UInt16
    ) -> [KeyBlockInfo] {
        let reader = createDataReader(buffer)
        var blocks: [KeyBlockInfo] = []
        for _ in 0..<blockCount {
            let keysCount: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            let firstWordLength = codingUnit * reader.get(reader.position, true) + codingUnit
            reader.position += 2
            // const firstWord = decoder.decode(new Uint8Array(buffer, reader.position, firstWordLength))
            reader.position += Buffer.Index(firstWordLength)
            let lastWordLength = codingUnit * reader.get(reader.position, true) + codingUnit
            reader.position += 2
            // const lastWord = decoder.decode(new Uint8Array(buffer, reader.position, lastWordLength))
            reader.position += Buffer.Index(lastWordLength)
            let compSize: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            let decompSize: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            blocks.append(KeyBlockInfo(keysCount, compSize, decompSize))
        }
        return blocks
    }

    func readString<Buffer: BufferSource>(
        _ reader: DataReader<Buffer>, _ encoding: String.Encoding, _ codingUnit: UInt16
    )
        -> String
    {
        let (str, len) = findString(reader, reader.position, encoding, codingUnit)
        reader.position += len
        return str
    }

    func findString<Buffer: BufferSource>(
        _ reader: DataReader<Buffer>, _ start: Buffer.Index, _ encoding: String.Encoding,
        _ codingUnit: UInt16
    ) -> (String, Buffer.Index) {
        var i: Buffer.Index = 0
        let codingUnit = Buffer.Index(codingUnit)
        let notEnding =
            codingUnit == 2
            ? {
                let c: UInt16 = reader.get($0, true)
                return c != 0
            }
            : {
                let c: UInt8 = reader.get($0, true)
                return c != 0
            }
        while notEnding(start + i) {
            i += codingUnit
        }
        let str = String(bytes: reader.getBuffer(start, count: Int(i)), encoding: encoding) ?? ""
        i += codingUnit
        return (str, i)
    }

    func readKeyInfos(
        _ buffer: [UInt8], _ keyInfosCount: Int, _ encoding: String.Encoding, _ codingUnit: UInt16
    ) -> [KeyInfo] {
        let reader = createDataReader(buffer)
        var keys: [KeyInfo] = []
        var lastKey: KeyInfo? = nil
        for _ in 0..<keyInfosCount {
            let offset: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            let key = readString(reader, encoding, codingUnit)
            let keyInfo = KeyInfo(key, offset)
            if let lastKey = lastKey {
                lastKey.count = Int(offset - lastKey.offset)
            }
            keys.append(keyInfo)
            lastKey = keyInfo
        }
        return keys
    }

    func readRecordBlockInfos(_ reader: FileDataReader) -> [RecBlockInfo] {
        var blocks: [RecBlockInfo] = []
        let recBlocksCount: UInt64 = reader.get(reader.position, true)
        reader.position += 8
        reader.position += 8  // num_entries
        reader.position += 8  // index_len
        reader.position += 8  // blocks_len
        for _ in 0..<recBlocksCount {
            let compSize: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            let decompSize: UInt64 = reader.get(reader.position, true)
            reader.position += 8
            blocks.append(RecBlockInfo(compSize, decompSize))
        }
        var dataStart: UInt64 = 0
        for block in blocks {
            block.start = UInt64(reader.position)
            reader.position += Int(block.compSize)
            block.dataStart = dataStart
            dataStart += block.decompSize
            block.dataEnd = dataStart
        }
        return blocks
    }

    func readRecordBuffer(_ reader: FileDataReader) -> [UInt8] {
        let recBlockInfos = readRecordBlockInfos(reader)
        let recBuffers = recBlockInfos.map {
            reader.position = Int($0.start)
            return decompAndDecryptBuffer(reader, Int($0.compSize))
        }
        return recBuffers.reduce([]) { (all, item) in all + item }
    }

    func readInfo(_ reader: FileDataReader) -> [String: String] {
        let infoLength: UInt32 = reader.get(reader.position, true)
        reader.position += 4
        let infoStr = String(
            bytes: reader.getBuffer(reader.position, count: Int(infoLength)),
            encoding: .utf16LittleEndian)!
        reader.position += Int(infoLength)
        reader.position += 4  // header checksunm
        let parser = XMLParser(data: Data(infoStr.utf8))
        let dictInfo = DictInfoParser()
        parser.delegate = dictInfo
        parser.parse()
        var info = dictInfo.info
        if info[DictInfoParser.StyleSheet] != nil && info[DictInfoParser.StyleSheet] != "",
            let match = infoStr.firstMatch(of: /StyleSheet\s*=\s*("|')((?:.|\n)*)\1/)
        {
            info[DictInfoParser.StyleSheet] = String(match.output.2)
        }
        return info
    }

    func checkEncrypted(_ info: [String: String]) -> Bool {
        let encrypted: Int = (try? Int(info[DictInfoParser.Encrypted] ?? "", format: .number)) ?? 0
        let headerEncrypted = encrypted & 1 != 0
        let indexEncrypted = encrypted & 2 != 0
        if headerEncrypted {
            fatalError()
        }
        return indexEncrypted
    }

    func checkEncoding(_ info: [String: String], _ defaultEncoding: String = "utf-8") -> (
        UInt16, String.Encoding
    ) {
        var encoding = info[DictInfoParser.Encoding] ?? ""
        if encoding == "" {
            encoding = defaultEncoding
        }
        var codingUnit: UInt16 = 0
        var decoder = String.Encoding.utf8
        switch encoding.lowercased() {
        case "utf-8":
            codingUnit = 1
            decoder = .utf8
            break
        case "utf-16":
            codingUnit = 2
            decoder = .utf16LittleEndian
            break
        default:
            fatalError()
        }
        return (codingUnit, decoder)
    }

    func readKeys(
        _ reader: FileDataReader, _ indexEncrypted: Bool, _ encoding: String.Encoding,
        _ codingUnit: UInt16
    ) -> [KeyInfo] {
        let blocksCount: UInt64 = reader.get(reader.position, true)
        reader.position += 8
        // const entriesCount = reader.getBigUint64(reader.position)
        reader.position += 8
        // const keyIndexDecompLen = reader.getBigUint64(reader.position)
        reader.position += 8
        let keyIndexCompLen: UInt64 = reader.get(reader.position, true)
        reader.position += 8
        // const keyBlockLen = reader.getBigUint64(reader.position)
        reader.position += 8
        // const keyInfoChecksum = new Uint8Array(reader.buffer, reader.position, 4)
        reader.position += 4
        let keyIndexBuffer = decompAndDecryptBuffer(reader, Int(keyIndexCompLen), indexEncrypted)
        let keyBlockInfos = readKeyBlockInfos(keyIndexBuffer, Int(blocksCount), codingUnit)
        var allKeys: [KeyInfo] = []
        for keyBlockInfo in keyBlockInfos {
            let blockBuffer = decompAndDecryptBuffer(reader, Int(keyBlockInfo.compSize))
            let keys = readKeyInfos(blockBuffer, Int(keyBlockInfo.keysCount), encoding, codingUnit)
            allKeys.append(contentsOf: keys)
        }
        return allKeys
    }

    typealias Index = Int
    typealias FileDataReader = DataReader<LazyData<Index>>

    func parseKeys(file: URL, parentInfo: [String: String]? = nil) throws -> (
        FileDataReader, [KeyInfo], [RecBlockInfo], [String: String], String.Encoding
    ) {
        let reader = createDataReader(try LazyData<Int>(contentsOf: file))
        let info = readInfo(reader)
        let indexEncrypted = checkEncrypted(info)
        let (codingUnit, encoding) = checkEncoding(info, "utf-16")
        let keys = readKeys(reader, indexEncrypted, encoding, codingUnit)
        let recBlockInfos = readRecordBlockInfos(reader)
        var currentBlockInfoId = 0
        for key in keys {
            while key.offset >= recBlockInfos[currentBlockInfoId].dataEnd {
                currentBlockInfoId += 1
                if currentBlockInfoId >= recBlockInfos.count {
                    fatalError("")
                }
            }
            key.blockId = currentBlockInfoId
            key.blockOffset = key.offset - recBlockInfos[currentBlockInfoId].dataStart
        }
        return (reader, keys, recBlockInfos, info, encoding)
    }

    func readKeyContentBuffer(
        _ reader: FileDataReader, _ key: KeyInfo, _ blocks: [RecBlockInfo]
    ) -> [UInt8] {
        let block = blocks[key.blockId]
        reader.position = Int(block.start)
        block.buffer = block.buffer ?? decompAndDecryptBuffer(reader, Int(block.compSize))
        let reader = createDataReader(block.buffer!)
        let buffers = reader.getBuffer(
            Int(key.blockOffset), count: key.count ?? Int((block.dataEnd - key.offset)))
        return buffers
    }

    func readKeyContent(
        _ reader: FileDataReader, _ key: KeyInfo, _ blocks: [RecBlockInfo],
        encoding: String.Encoding
    ) -> String {
        let block = blocks[key.blockId]
        reader.position = Int(block.start)
        block.buffer = block.buffer ?? decompAndDecryptBuffer(reader, Int(block.compSize))
        let reader = createDataReader(block.buffer!)
        let buffers = reader.getBuffer(
            Int(key.blockOffset), count: key.count ?? Int((block.dataEnd - key.offset)))
        return String(bytes: buffers, encoding: encoding) ?? ""
    }
}

private class DictInfoParser: NSObject, XMLParserDelegate {
    static let Encrypted: String = "Encrypted"
    static let Encoding: String = "Encoding"
    static let StyleSheet: String = "StyleSheet"
    var info: [String: String] = [:]
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        for (attr_key, attr_val) in attributeDict {
            switch attr_key {
            case Self.Encoding, Self.Encrypted, Self.StyleSheet:
                info[attr_key] = attr_val
            default:
                continue
            }
        }
    }
}

private struct KeyBlockInfo {
    let keysCount: UInt64
    let compSize: UInt64
    let decompSize: UInt64
    init(_ keysCount: UInt64, _ compSize: UInt64, _ decompSize: UInt64) {
        self.keysCount = keysCount
        self.compSize = compSize
        self.decompSize = decompSize
    }
}

private class KeyInfo {
    let key: String
    let offset: UInt64
    var count: Int? = nil
    var blockId: Int = 0
    var blockOffset: UInt64 = 0
    init(_ key: String, _ offset: UInt64) {
        self.key = key
        self.offset = offset
    }
}

private class RecBlockInfo {
    let compSize: UInt64
    let decompSize: UInt64
    var start: UInt64 = 0
    var end: UInt64 = 0
    var dataStart: UInt64 = 0
    var dataEnd: UInt64 = 0
    var buffer: [UInt8]? = nil
    init(_ compSize: UInt64, _ decompSize: UInt64) {
        self.compSize = compSize
        self.decompSize = decompSize
    }
}
