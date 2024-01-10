//
//  TxtMeasurer.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/18.
//

import AppCommon
import Foundation

public struct MeasuredCharacter {
    let x: Int
    let y: Int
    let offset: Int
    let half: Bool
    let width: Int
    let height: Int
    let char: Character
    let tag: Character?
    var newLine: Bool = false
}

public protocol MeasuredTextTag {
    var open: Character { get }
    var close: Character { get }
    var small: Bool { get }
}

public struct TxtLayoutOption {
    let tags: [Character: any MeasuredTextTag]
    let ignoreChars: Set<Character>
    let halfChars: Set<Character>
    let sizes: (Int, Int)
    let maxEmptyLines: Int?
    init(
        tags: [Character: any MeasuredTextTag], ignoreChars: Set<Character>,
        halfChars: Set<Character>, sizes: (Int, Int), maxEmptyLines: Int? = 1
    ) {
        self.tags = tags
        self.ignoreChars = ignoreChars
        self.halfChars = halfChars
        self.sizes = sizes
        self.maxEmptyLines = maxEmptyLines
    }
}

public protocol TxtMeasurer {
    func getPage(
        _ content: any CharsSequence,
        _ startIndex: Int,
        currentTag: Character?,
        cellColumns: Int,
        cellRows: Int,
        option: TxtLayoutOption
    ) -> ([([MeasuredCharacter], Int, Range<Int>, Character?)], String, Int, Character?)
}

private class TxtMeasurerImpl: TxtMeasurer {
    func getPage(
        _ content: any CharsSequence,
        _ startIndex: Int,
        currentTag: Character?,
        cellColumns: Int,
        cellRows: Int,
        option: TxtLayoutOption
    ) -> ([([MeasuredCharacter], Int, Range<Int>, Character?)], String, Int, Character?) {
        let normalSize = option.sizes.0
        let halfNormalSize = option.sizes.0 / 2
        let smallSize = option.sizes.1
        let halfSmallSize = option.sizes.1 / 2
        let smallColumns = 2
        var chars: [([MeasuredCharacter], Int, Range<Int>, Character?)] = []
        var line: [MeasuredCharacter] = []
        var lineCells = 0
        var x = 0
        var y = 0
        var tag: MeasuredTextTag? = nil
        var lineStartTag: Character? = currentTag
        var smallChar = false
        var updateSmallChar = false
        var fromColumn = 0
        var toColumn = 0
        var secondRow = false
        let closeTags: [Character: any MeasuredTextTag] = .init(
            uniqueKeysWithValues: option.tags.map { ($0.value.close, $0.value) })
        content.seek(startIndex)
        var lineStart = content.offset
        let newLine: (Bool) -> Void = { actualNewLine in
            x = 0
            y += normalSize
            var newLine = line
            if !newLine.isEmpty {
                newLine[newLine.count - 1].newLine = actualNewLine
            }
            chars.append((newLine, lineCells, lineStart..<content.offset, lineStartTag))
            lineStart = content.offset
            lineStartTag = tag?.open
            line = []
            lineCells = 0
        }
        if currentTag != nil && option.tags[currentTag!] != nil {
            tag = option.tags[currentTag!]
            if tag!.small {
                smallChar = true
                updateSmallChar = true
            }
        }

        var emptyLines = 1
        while let (offset, ch) = content.next() {
            if option.ignoreChars.contains(ch) {
                continue
            }
            if ch == "\r\n" || ch == "\n" || ch == "\r" {
                if ch == "\r" {
                    let next = content.next()
                    if next != nil && next!.1 != "\n" {
                        content.seek(next!.0)
                    }
                }

                if emptyLines == 0 || option.maxEmptyLines == nil
                    || emptyLines <= option.maxEmptyLines!
                {
                    newLine(true)
                }

                emptyLines += 1

                if y >= cellRows {
                    break
                }
                continue
            }
            if currentTag == nil && tag == nil && closeTags[ch] != nil {
                return getPage(
                    content, startIndex, currentTag: closeTags[ch]!.open,
                    cellColumns: cellColumns,
                    cellRows: cellRows, option: option)
            }
            if tag == nil && option.tags[ch] != nil {
                tag = option.tags[ch]
                if tag!.small {
                    smallChar = true
                    updateSmallChar = true
                }
                continue
            }

            if tag != nil && tag?.close == ch {
                tag = nil
                smallChar = false
                updateSmallChar = false
                x = toColumn
                continue
            }

            if updateSmallChar {
                let needColumns = {
                    defer {
                        content.loadOffset()
                    }
                    var needCells = 0
                    content.saveOffset()
                    content.seek(offset)

                    let remainColumns = cellColumns - x
                    let remainLineCells = remainColumns * smallColumns
                    while let (offsetJ, ch) = content.next() {
                        if option.ignoreChars.contains(ch) {
                            continue
                        }
                        if ch == tag?.close {
                            content.seek(offsetJ)
                            break
                        }
                        needCells += option.halfChars.contains(ch) ? halfSmallSize : smallSize
                        if needCells >= remainLineCells {
                            return remainColumns
                        }
                    }
                    let needColumns =
                        (needCells % smallColumns == 0 ? 0 : 1) + needCells / smallColumns
                    var x$ = 0
                    let toOffset = content.offset
                    content.seek(offset)
                    var secondRow = false
                    while let (offsetK, ch) = content.next(), offsetK < toOffset {
                        if option.ignoreChars.contains(ch) {
                            continue
                        }
                        let dx = option.halfChars.contains(ch) ? halfSmallSize : smallSize
                        if x$ + dx > needColumns {
                            if !secondRow {
                                secondRow = true
                                x$ = 0
                                content.seek(offsetK)
                                continue
                            }
                            return min(x$ + dx, remainColumns)
                        }
                        x$ += dx
                    }
                    return min(needColumns, remainColumns)
                }()
                fromColumn = x
                toColumn = x + needColumns
                secondRow = false
                updateSmallChar = false
            }

            let offsetY = smallChar ? (secondRow ? 1 : -1) : 0

            let half = option.halfChars.contains(ch)
            let dx =
                half
                ? (smallChar ? halfSmallSize : halfNormalSize)
                : (smallChar ? smallSize : normalSize)

            if smallChar {
                if x + dx > toColumn {
                    if !secondRow {
                        secondRow = true
                        x = fromColumn
                        content.seek(offset)
                        continue
                    } else {
                        content.seek(offset)
                        newLine(false)
                        if y >= cellRows {
                            break
                        }
                        updateSmallChar = true
                        continue
                    }
                }
            } else {
                if x + dx >= cellColumns {
                    content.seek(offset)
                    newLine(false)
                    if y >= cellRows {
                        break
                    }
                    continue
                }
            }

            line.append(
                .init(
                    x: x, y: y,
                    offset: offsetY,
                    half: half,
                    width: dx,
                    height: smallChar ? smallSize : normalSize,
                    char: ch, tag: tag?.open))
            lineCells = max(lineCells, x + dx)
            x += dx
            emptyLines = 0
        }
        if content.offset > lineStart {
            chars.append(
                (line, lineCells, lineStart..<content.offset, lineStartTag))
        }
        return (chars, content[startIndex..<content.offset] ?? "", content.offset, tag?.open)
    }
}

public let TxtMeasurer$ = { TxtMeasurerImpl() as any TxtMeasurer }
