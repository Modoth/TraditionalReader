//
//  FileReaderPage.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/31.
//

import Foundation

enum FileReaderPageSide {
    case none
    case left
    case right
    case both
}

class FileReaderPage: ObservableObject, Equatable, Hashable {

    static func == (lhs: FileReaderPage, rhs: FileReaderPage) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    @Published var name: String
    @Published var url: URL
    @Published var width: Int?
    @Published var height: Int?
    @Published var page: Int?
    @Published var relativePage: Bool
    @Published var position: Range<Int>?
    @Published var totalPosition: Range<Int>?
    @Published var minPage: Int?
    @Published var maxPage: Int?
    @Published var side: FileReaderPageSide
    init(
        name: String, url: URL, width: Int? = nil, height: Int? = nil, page: Int? = nil,
        relativePage: Bool = false,
        position: Range<Int>? = nil,
        totalPosition: Range<Int>? = nil,
        minPage: Int? = nil,
        maxPage: Int? = nil,
        side: FileReaderPageSide = .none,
        rightPage: Bool? = nil
    ) {
        self.name = name
        self.url = url
        self.width = width
        self.height = height
        self.page = page
        self.relativePage = relativePage
        self.position = position
        self.totalPosition = totalPosition
        self.minPage = minPage
        self.maxPage = maxPage
        self.side = side
    }

    private var pager: BookReaderPager?
    private var listener: UUID?

    func setInitPosition(
        position: Int,
        approximatePosition: Bool,
        minPagesCount: Int?,
        pager: BookReaderPager,
        success: ((Int, Range<Int>, Range<Int>, Bool) -> Void)? = nil
    ) {
        self.releasePager()
        self.page = nil
        self.position = nil
        listener = pager.getPageForInitPosition(position, approximatePosition, minPagesCount) {
            self.page = $0
            self.position = $1
            self.totalPosition = $1
            self.relativePage = $3
            self.releasePager()
            success?($0, $1, $2, $3)
        }
    }

    func setIdx(idx: Int, pager: BookReaderPager, success: ((Range<Int>) -> Void)? = nil) {
        self.releasePager()
        self.page = idx
        self.position = nil
        listener = pager.getPositionForPage(idx) {
            self.page = idx
            self.position = $0
            self.releasePager()
            success?($0)
        }
    }

    @discardableResult
    func setAsMin(_ pager: BookReaderPager, success: ((Int) -> Void)? = nil) -> Self {
        assert(self.pager == nil)
        listener = pager.getMinPage {
            self.minPage = $0
            self.releasePager()
            success?(Int($0))
        }
        return self
    }

    @discardableResult
    func setAsMax(_ pager: BookReaderPager, success: ((Int) -> Void)? = nil) -> Self {
        assert(self.pager == nil)
        listener = pager.getMaxPage {
            self.maxPage = $0
            self.releasePager()
            success?(Int($0))
        }
        return self
    }

    private func releasePager() {
        guard let listener = listener, let pager = pager else {
            return
        }
        self.listener = nil
        self.pager = nil
        pager.unregisterEvent(listener)
    }

    deinit {
        releasePager()
    }
}
