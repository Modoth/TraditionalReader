//
//  TxtPager.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/7.
//

import AppCommon
import Foundation

public protocol TxtPager: AnyObject {
    func config(
        file: URL,
        initPosition: Int,
        approximatePosition: Bool,
        width: Int, height: Int,
        minPagesCount: Int?,
        layoutOption: TxtLayoutOption) throws
    var totalPosition: Int? { get }
    func getPageContent(_ pageId: Int) -> String
    func getPage(_ pageId: Int, setPage: @escaping (Bool, Range<Int>, Range<Int>) -> Void) -> UUID?
    func getMinPage(setMinPage: @escaping (Bool, Int) -> Void) -> UUID?
    func getMaxPage(setMaxPage: @escaping (Bool, Int) -> Void) -> UUID?
    func unregister(id: UUID)
    func dispose()
}

public let TxtPager$ = { TxtPagerImpl() as any TxtPager }

private struct PagerOption {
    let file: URL
    let initPosition: Int
    let layoutOption: TxtLayoutOption
    let width: Int
    let height: Int
    let cellColumns: Int
    let cellRowsPerHeight: Int
    let data: FileCharsSequence
}

private class TxtPagerImpl: TxtPager, Service {
    private struct Option {
        let file: URL
        let width: Int
        let height: Int
        let cellColumns: Int
        let cellRows: Int
        let data: FileCharsSequence
    }

    private var forwardPager: ForwardPager? = nil
    private var backwardPager: BackwardPager? = nil
    func config(
        file: URL, initPosition: Int,
        approximatePosition: Bool,
        width: Int, height: Int,
        minPagesCount: Int?,
        layoutOption: TxtLayoutOption
    ) throws {
        let searchFor = "\n"
        let maxSearch = PagerBase.aveBytesPerWord * width * min(2, height / 3)
        if forwardPager != nil {
            let forwardData = forwardPager!.option.data
            if forwardPager!.option.initPosition == initPosition {
                return
            }
            if approximatePosition {
                let latestLinePos = forwardData.search(
                    searchFor, latestBefore: initPosition,
                    maxSearch: maxSearch)
                if forwardPager!.option.initPosition == latestLinePos?.upperBound {
                    return
                }
            }
            forwardPager!.dispose()
        }
        if backwardPager != nil {
            backwardPager!.dispose()
        }
        forwardPager = nil
        backwardPager = nil

        let cellColumns = width * layoutOption.sizes.0
        let measurer: TxtMeasurer = locate()

        let forwardData = try FileCharsSequence(file)
        if approximatePosition {
            let latestLinePos = forwardData.search(
                searchFor, latestBefore: initPosition,
                maxSearch: maxSearch)
            forwardData.seek(nearAfter: latestLinePos?.upperBound ?? initPosition)
        } else {
            forwardData.seek(nearAfter: initPosition)
        }
        let validInitPosition = forwardData.offset
        forwardPager = ForwardPager(
            option: PagerOption(
                file: file,
                initPosition: validInitPosition,
                layoutOption: layoutOption,
                width: width, height: height, cellColumns: cellColumns,
                cellRowsPerHeight: layoutOption.sizes.0,
                data: forwardData),
            measurer: measurer, minPagesCount: minPagesCount)
        if validInitPosition > 0 {
            let backwardData = try FileCharsSequence(file)
            backwardData.setIterEnd(validInitPosition)
            backwardPager = BackwardPager(
                option: PagerOption(
                    file: file,
                    initPosition: initPosition,
                    layoutOption: layoutOption,
                    width: width, height: height, cellColumns: cellColumns,
                    cellRowsPerHeight: layoutOption.sizes.0,
                    data: backwardData),
                measurer: measurer, minPagesCount: minPagesCount)
        }
    }

    func getMinPage(setMinPage: @escaping (Bool, Int) -> Void) -> UUID? {
        if forwardPager?.option.initPosition == 0 {
            setMinPage(true, -1)
            return nil
        }
        return backwardPager?.getTotalPage {
            setMinPage($0, $1)
        }
    }

    func getMaxPage(setMaxPage: @escaping (Bool, Int) -> Void) -> UUID? {
        return forwardPager?.getTotalPage {
            setMaxPage($0, $1)
        }
    }

    var totalPosition: Int? {
        forwardPager?.option.data.count ?? backwardPager?.option.data.count
    }

    func getPageContent(_ pageId: Int) -> String {
        (pageId >= 0 ? forwardPager?.getPageContent(pageId) : backwardPager?.getPageContent(pageId))
            ?? ""
    }

    func getPage(_ pageId: Int, setPage: @escaping (Bool, Range<Int>, Range<Int>) -> Void) -> UUID?
    {
        pageId >= 0
            ? forwardPager?.getPage(pageId, setPage: setPage)
            : backwardPager?.getPage(pageId, setPage: setPage)
    }

    func dispose() {
        forwardPager?.dispose()
        backwardPager?.dispose()
    }

    func unregister(id: UUID) {
        forwardPager?.unregister(id: id)
        backwardPager?.unregister(id: id)
    }
}

private class PagerBase {
    static let aveBytesPerWord = 6
    static let minPageCaches = 5
    static let maxPageCaches = 20

    let option: PagerOption
    let measurer: TxtMeasurer
    let minPagesCount: Int

    init(option: PagerOption, measurer: TxtMeasurer, minPagesCount: Int?) {
        self.option = option
        self.measurer = measurer
        self.minPagesCount = minPagesCount ?? 1
        offset = option.initPosition
    }

    func getPageContent(_ pageId: Int) -> String {
        guard let page = caches.tryGet(getCacheId(pageId)) else {
            return ""
        }
        return (page.tag != nil ? String(page.tag!) : "") + (option.data[page.range] ?? "")
    }

    func getTotalPage(setTotalPage: @escaping (Bool, Int) -> Void) -> UUID? {
        if allCached {
            setTotalPage(true, getPageId(caches.count))
            return nil
        }
        let id = UUID()
        totalPageListeners[id] = { setTotalPage(false, $0) }
        return id
    }

    func onTotalPages() {
        let totalPage = getPageId(caches.count)
        for l in totalPageListeners {
            l.value(totalPage)
        }
    }

    var caches: [(range: Range<Int>, tag: Character?)] = []

    var tryCacheTo: Int = 0

    var cachingTask: Task<(), Never>? = nil
    var offset: Int = 0
    var currentTag: Character? = nil
    var allCached = false

    func getCacheId(_ pageId: Int) -> Int {
        fatalError("Not implemented.")
    }

    func getPageId(_ cacheId: Int) -> Int {
        fatalError("Not implemented.")
    }

    func cachingPages(to pageId: Int) {
        fatalError("Not implemented.")
    }

    var taskIdToPages: [UUID: Int] = [:]
    var pageListeners: [Int: [UUID: (Range<Int>) -> Void]] = [:]
    var totalPageListeners: [UUID: (Int) -> Void] = [:]

    func registerPaged(_ pageId: Int, onPage: @escaping (Range<Int>) -> Void) -> UUID {
        let id = UUID()
        if pageListeners[pageId] == nil {
            pageListeners[pageId] = [:]
        }
        taskIdToPages[id] = pageId
        pageListeners[pageId]![id] = onPage
        return id
    }

    func getPage(_ pageId: Int, setPage: @escaping (Bool, Range<Int>, Range<Int>) -> Void) -> UUID?
    {
        let cacheId = getCacheId(pageId)
        cachingPages(to: pageId)
        if caches.count > cacheId {
            setPage(true, caches[cacheId].range, 0..<self.option.data.count)
            return nil
        }

        return registerPaged(pageId) {
            setPage(false, $0, 0..<self.option.data.count)
        }
    }

    func unregister(id: UUID) {
        totalPageListeners[id] = nil
        guard let pageId = taskIdToPages[id] else {
            return
        }
        taskIdToPages[id] = nil
        pageListeners[pageId]![id] = nil
    }

    func dispose() {
        cachingTask?.cancel()
    }
}

private class ForwardPager: PagerBase {
    override func getCacheId(_ pageId: Int) -> Int {
        return pageId
    }

    override func getPageId(_ cacheId: Int) -> Int {
        cacheId
    }

    override func cachingPages(to pageId: Int) {
        let cacheId = getCacheId(pageId)
        if allCached || tryCacheTo - cacheId >= Self.minPageCaches {
            return
        }

        tryCacheTo = max(cacheId == 0 ? minPagesCount : (cacheId + Self.maxPageCaches), tryCacheTo)

        if cachingTask != nil {
            return
        }

        cachingTask = Task(priority: .background) {
            defer {
                DispatchQueue.main.sync {
                    self.cachingTask = nil
                }
            }
            var allCached = self.allCached
            var offset = self.offset
            var currentTag = self.currentTag
            while !allCached && self.caches.count < tryCacheTo {
                var newCachedPages: [(range: Range<Int>, tag: Character?)] = []

                while newCachedPages.count < Self.minPageCaches {
                    if Task.isCancelled {
                        return
                    }
                    let (_, _, next, tag) = measurer.getPage(
                        option.data, offset, currentTag: currentTag,
                        cellColumns: option.cellColumns,
                        cellRows: option.cellRowsPerHeight * option.height,
                        option: option.layoutOption)
                    if offset >= next {
                        allCached = true
                        break
                    }
                    let pageRange = offset..<next
                    newCachedPages.append((pageRange, currentTag))
                    offset = next
                    currentTag = tag
                }

                DispatchQueue.main.sync {
                    for (i, p) in newCachedPages.enumerated() {
                        let pageIdx = self.caches.count + i
                        self.caches.append(p)
                        let listeners = self.pageListeners[pageIdx]
                        if listeners != nil {
                            self.pageListeners[pageIdx] = nil
                            for l in listeners! {
                                l.value(p.range)
                                taskIdToPages[l.key] = nil
                            }
                        }
                    }
                    self.allCached = allCached
                    self.offset = offset
                    self.currentTag = currentTag
                    if allCached {
                        onTotalPages()
                    }
                }
            }
        }
    }
}

private class BackwardPager: PagerBase {

    override func getCacheId(_ pageId: Int) -> Int {
        return -pageId - 1
    }

    override func getPageId(_ cacheId: Int) -> Int {
        -cacheId - 1
    }

    override func cachingPages(to pageId: Int) {
        if option.initPosition <= 0 || allCached {
            return
        }
        let cacheId = getCacheId(pageId)
        if tryCacheTo - cacheId >= Self.minPageCaches {
            return
        }

        tryCacheTo = max(cacheId + Self.maxPageCaches, tryCacheTo)

        if cachingTask != nil {
            return
        }

        cachingTask = Task(priority: .background) {
            defer {
                DispatchQueue.main.sync {
                    self.cachingTask = nil
                }
            }
            var allCached = self.allCached
            var offset = self.offset
            while !allCached && self.caches.count < tryCacheTo {
                let lines = option.height * Self.minPageCaches
                let aprosBytesCount =
                    min(offset, Self.aveBytesPerWord * option.width * lines)
                var start = offset - aprosBytesCount
                let latestLinePos = option.data.search(
                    "\n", latestBefore: start, maxSearch: aprosBytesCount)
                start = latestLinePos?.upperBound ?? start
                option.data.seek(nearBefore: start)
                start = option.data.offset
                option.data.setIterEnd(offset)
                let (tokens, _, _, _) = measurer.getPage(
                    option.data, start, currentTag: nil,
                    cellColumns: option.cellColumns,
                    cellRows: Int.max, option: option.layoutOption)
                var newCachedPages: [(range: Range<Int>, tag: Character?)] = []
                let newCachedCount =
                    tokens.count / option.height
                    + ((start == 0 && tokens.count % option.height != 0) ? 1 : 0)
                for i in 0..<newCachedCount {
                    let startLine = tokens[max(0, tokens.count - (i + 1) * option.height)]
                    let endLine = tokens[tokens.count - i * option.height - 1]
                    newCachedPages.append(
                        (startLine.2.lowerBound..<endLine.2.upperBound, startLine.3))
                }

                offset = newCachedPages.last?.range.lowerBound ?? 0
                allCached = offset == 0

                DispatchQueue.main.sync {
                    for (i, p) in newCachedPages.enumerated() {
                        let pageIdx = getPageId(self.caches.count + i)
                        self.caches.append(p)
                        let listeners = self.pageListeners[pageIdx]
                        if listeners != nil {
                            self.pageListeners[pageIdx] = nil
                            for l in listeners! {
                                l.value(p.range)
                                taskIdToPages[l.key] = nil
                            }
                        }
                    }
                    self.offset = offset
                    self.allCached = allCached
                    if allCached {
                        onTotalPages()
                    }
                }
            }
        }
    }
}
