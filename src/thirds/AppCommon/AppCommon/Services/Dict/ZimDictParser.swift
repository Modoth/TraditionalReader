//
//  ZimDictParser.swift
//  AppCommon
//
//  Created by zxq on 2023/11/20.
//

import Compression
import Foundation
import libzstd

private struct Header: DataSimpleReadable, Equatable {
    /// 0x44D495A
    let magicNumber: UInt32
    let majorVersion: UInt16
    /// 0: old namesapce, 1: new namespace
    let minorVersion: UInt16
    let uuid: UUID
    let entryCount: UInt32
    let clusterCount: UInt32
    let urlPtrPos: UInt64
    /// obsolete
    let titlePtrPos: UInt64
    let clusterPtrPos: UInt64
    let mimeListPos: UInt64
    /// 0xffffffff if no main page
    let mainPage: UInt32
    /// 0xffffffff if no layout page
    let layoutPage: UInt32
    /// md5 of archive without itself, 16 bytes from end
    let checksumPos: UInt64
}

private protocol Entry {
    var namespace: UInt8 { get }
    var mimetype: UInt16 { get }
    var url: String { get }
    var title: String { get }
}

private struct DirectoryEntry: Entry {
    // mime id
    let mimetype: UInt16
    let parameterLen: UInt8
    /// char
    let namespace: UInt8
    /// not used
    let revision: UInt32
    let clusterNumber: UInt32
    let blobNumber: UInt32
    let url: String
    let title: String
    /// not used
    let parameter: [UInt8]
}

private struct RedirectEntry: Entry {
    // mime id
    let mimetype: UInt16
    let parameterLen: UInt8
    /// char
    let namespace: UInt8
    /// not used
    let revision: UInt32
    let redirectIndex: UInt32
    let url: String
    let title: String
    /// not used
    let parameter: [UInt8]
}

public let ZimDictParser$ = { ZimDictParser() as any DictParser }

class ZimDictParser: DictParser {
    init() {}
    func parse(_ file: URL, _ dicFile: DictFile) throws -> (
        info: [String: String],
        sections: [DictSection],
        items: [DictItem]
    ) {
        let info: [String: String] = [
            "Encoding": "utf-8"
        ]
        let reader = DataReader(try LazyData<UInt64>(contentsOf: file))
        let header: Header = reader.read()
        var mimes: [String] = []
        while true {
            let mime: String = reader.read()
            if mime == "" {
                break
            }
            mimes.append(mime)
        }
        reader.position = header.urlPtrPos
        let urlPointers: [UInt64] = (0..<header.entryCount).map { _ in reader.read() }

        reader.position = header.clusterPtrPos
        let clusterPointers: [UInt64] = (0..<header.clusterCount).map { _ in reader.read() }

        let entries = urlPointers.map {
            reader.position = $0
            let mimeType: UInt16 = reader.read()
            reader.position = $0
            if mimeType == 0xffff {
                return RedirectEntry(
                    mimetype: reader.read(), parameterLen: reader.read(),
                    namespace: reader.read(), revision: reader.read(),
                    redirectIndex: reader.read(),
                    url: reader.read(), title: reader.read(),
                    parameter: []) as any Entry

            } else {
                return DirectoryEntry(
                    mimetype: reader.read(), parameterLen: reader.read(),
                    namespace: reader.read(), revision: reader.read(),
                    clusterNumber: reader.read(), blobNumber: reader.read(),
                    url: reader.read(), title: reader.read(),
                    parameter: []) as any Entry
            }
        }

        var sections: [DictSection] = []

        for clusterPos in clusterPointers {
            reader.position = clusterPos
            /// 0F: 1 no compress, 4: LZMA2, 5: zstd
            /// F0: 0 normal, OFFSET_SIZE = 4 bytes, max 4G;  1: extended OFFSET_SIZE = 8, major version >= 6 only
            let clusterInformation: UInt8 = reader.read()
            let section = DictSection()
                .with(\.id, UUID())
                .with(\.file, dicFile.id)
                .with(\.start, reader.position)
                .with(\.metaInfo, UInt64(clusterInformation))
            sections.append(section)
        }
        let isArticle: (any Entry) -> Bool =
            header.minorVersion == 0 ? { $0.namespace == 65 } : { $0.namespace == 67 }
        let findContentEntry: (Entry) -> DirectoryEntry? = { entry in
            var current: (any Entry)? = entry
            var maxJump = 10
            while current != nil && maxJump > 0 {
                if current!.mimetype != 0xffff {
                    return current as? DirectoryEntry
                }
                current = entries.tryGet(Int((current as! RedirectEntry).redirectIndex))
                maxJump += 1
            }
            return nil
        }
        let items = entries.map { entry in
            let item = DictItem()
                .with(\.id, UUID())
                .with(\.dict, dicFile.dict)
                .with(\.key, entry.url)
            if isArticle(entry) {
                item.title = entry.title
            }
            guard let entry = findContentEntry(entry),
                let section = sections.tryGet(Int(entry.clusterNumber))
            else {
                return nil as (DictItem?)
            }
            item.section = section.id
            item.start = UInt64(entry.blobNumber)
            return item
        }.notNils()
        return (info, sections, items)
    }

    func getItemBlock(_ item: DictItem, _ section: DictSection, in buffer: [UInt8]) throws
        -> [UInt8]
    {
        let normalSize = section.metaInfo & 0xF0 == 0
        precondition(normalSize)
        let offsetSize = normalSize ? 4 : 8
        let reader = DataReader(buffer)
        let readOffset: () -> UInt64 =
            normalSize
            ? {
                let i: UInt32 = reader.read()
                return UInt64(i)
            }
            : { reader.read() }
        reader.position = Int(item.start) * offsetSize
        let start = readOffset()
        let end = readOffset()

        return Array(buffer[Int(start)..<Int(end)])
    }

    func decodeSection(_ section: DictSection, url: URL) throws -> [UInt8] {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
        guard let fileSize = attr[FileAttributeKey.size] as? UInt64 else {
            throw URLError(.cannotOpenFile)
        }
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer {
            try? fileHandle.close()
        }
        try fileHandle.seek(toOffset: section.start)
        let compressType = section.metaInfo & 0x0F
        precondition(compressType == 5)
        return try! ZstdDecompressor.decompress { (p, count) in
            let count = min(
                Int(fileSize - (try! fileHandle.offset())), count)
            if count == 0 {
                return count
            }
            let buffer = try! fileHandle.read(upToCount: count)!
            for i in 0..<count {
                p[i] = buffer[i]
            }
            return count
        }
    }
}

private class ZstdDecompressor {
    struct ZstdError: Error, LocalizedError {
        private let errorString: String

        init(errno: errno_t) {
            errorString = String(utf8String: strerror(errno)) ?? "Unknown"
        }

        init?(error: size_t) {
            if ZSTD_isError(error) == 0 {
                return nil
            }
            if let cString = ZSTD_getErrorName(error),
                let string = String(utf8String: cString)
            {
                errorString = string
            } else {
                errorString = "Zstd error \(error)"
            }
        }

        var localizedDescription: String { errorString }
    }

    static func decompress(read: (UnsafeMutablePointer<UInt8>, Int) -> Int) throws -> [UInt8] {
        var outputData = Data()
        let stream = ZSTD_createDStream()
        defer { ZSTD_freeDStream(stream) }
        var sourceRead = ZSTD_initDStream(stream)
        if let error = ZstdError(error: sourceRead) {
            throw error
        }

        let sourceBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: ZSTD_DStreamInSize())
        let destinationCapacity = ZSTD_DStreamOutSize()
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationCapacity)
        while true {
            var sourceCount = read(sourceBuffer, sourceRead)
            if sourceCount == 0 {
                break
            }
            var inBuffer = ZSTD_inBuffer(src: sourceBuffer, size: sourceCount, pos: 0)
            var outBuffer = ZSTD_outBuffer(
                dst: destinationBuffer, size: destinationCapacity, pos: 0)

            while inBuffer.pos < inBuffer.size {
                sourceRead = ZSTD_decompressStream(stream, &outBuffer, &inBuffer)
                if let error = ZstdError(error: sourceRead) {
                    throw error
                }

                var data = Data(bytes: outBuffer.dst, count: outBuffer.pos)
                outputData.append(data)
            }
        }

        return outputData.withUnsafeBytes { Array($0) }
    }
}

private class Cluster {
    let loadBuffer: () -> [UInt8]
    let loadBlobs: ([UInt8]) -> [Blob]
    init(loadBuffer: @escaping () -> [UInt8], loadBlobs: @escaping ([UInt8]) -> [Blob]) {
        self.loadBuffer = loadBuffer
        self.loadBlobs = loadBlobs
    }

    var _buffer: [UInt8]? = nil
    var buffer: [UInt8] {
        if _buffer == nil {
            _buffer = loadBuffer()
        }
        return _buffer!
    }

    var _blobs: [Blob]? = nil
    var blobs: [Blob] {
        if _blobs == nil {
            _blobs = loadBlobs(buffer)
        }
        return _blobs!
    }

}

private class Blob {
    let start: UInt64
    let end: UInt64

    let loadBuffer: (UInt64, UInt64) -> [UInt8]
    init(start: UInt64, end: UInt64, loadBuffer: @escaping (UInt64, UInt64) -> [UInt8]) {
        self.start = start
        self.end = end
        self.loadBuffer = loadBuffer
    }

    var _buffer: [UInt8]? = nil
    var buffer: [UInt8] {
        if _buffer == nil {
            _buffer = loadBuffer(start, end)
        }
        return _buffer!
    }
}
