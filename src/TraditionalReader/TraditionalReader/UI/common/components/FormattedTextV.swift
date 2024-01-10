//
//  FormattedTextV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/18.
//

import AppCommon
import Foundation
import SwiftUI

struct IntCoordinate: Hashable, Equatable {
    let x: Int
    let y: Int
}

struct FormattedTextV: UpdatableComponentBase, CopyWithable {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var tapHandler: OO<TagHandler>

    @EnvironmentObject var style: OO<Style>
    @EnvironmentObject var tags: OO<[Character: Tag]>
    @EnvironmentObject var textDirection: OO<TextDirection>
    @EnvironmentObject var missingChar: OO<MissingChar>
    @EnvironmentObject var charOptions: OO<CharsOptions>

    public var columns: Int?
    public var rows: Int?
    public var charsMap: [Character: Character] = [:]
    public var nopaddingFixChars: Set<Character> = ["　"]

    private let content: String

    let glyphsService = GlyphsService.singleton

    var updateBys: [(any Equatable)?]? {
        [
            selectedChars,
            content,
        ]
    }
    var forceUpdateBy: ForceUpdateBy? { nil }

    init(_ content: String) {
        self.content = content
    }

    @GestureState var fingerLocation: CGPoint? = nil
    @State public var selectedChars: Set<IntCoordinate> = []
    @State public var selection: String? = nil

    var updatableBody: some View {
        let _ = Self._printTrace()
        GeometryReader { proxy in
            let sizes = style%!.smallFont
            let normalCells = sizes.0
            let size = proxy.size
            let horizontal = textDirection%! == .horizontal

            let lineHeight = style%!.fontSize * style%!.lineHeight
            let charWidth = style%!.fontSize * style%!.charWidth

            let pageWidth = horizontal ? size.width : size.height
            let pageHeight = horizontal ? size.height : size.width

            let cellColumns = (columns == nil ? Int(pageWidth / charWidth) : columns!) * normalCells
            let cellRows = (rows == nil ? Int(pageHeight / lineHeight) : rows!) * normalCells
            let cellHeight = pageHeight / Double(cellRows)
            let measurer: TxtMeasurer = locate()
            let (chars, _, _, _) = measurer.getPage(
                StringCharsSequence(content), 0, currentTag: nil, cellColumns: cellColumns,
                cellRows: cellRows,
                option: TxtLayoutOption(
                    tags: tags%!,
                    ignoreChars: charOptions%!.ignoreChars,
                    halfChars: charOptions%!.halfChars, sizes: sizes))

            var displayChars: [Character] = []
            var charMap: [IntCoordinate: Int] = [:]
            var selectionRect: (minX: Double, minY: Double, maxX: Double, maxY: Double) = (
                proxy.size.width, proxy.size.height, 0, 0
            )
            var displayContent = ""
            let normalFont = (style%!.fontNames, style%!.fontSize, style%!.foreground)
            let perOffset: Double = cellHeight * Double(normalCells) / 4.0 - 1.0
            let tagFonts = Dictionary(
                uniqueKeysWithValues: tags%!.map { k, v in
                    (
                        k,
                        (
                            v.fontNames ?? normalFont.0,
                            v.relativeSize == .normal
                                ? style%!.fontSize
                                : style%!.fontSize * Double(sizes.1) / Double(sizes.0),
                            v.foreground ?? style%!.foreground
                        )
                    )
                })
            var map: [[(Double, Double, Int)]] = []
            let onPos: (CGPoint, Bool) -> Void = { loc, finished in
                let pos: (x: Double, y: Double) =
                    horizontal ? (loc.x, loc.y) : (loc.y, proxy.size.width - loc.x)
                let y = Int(pos.y * 2 / (cellHeight * Double(normalCells)))
                if finished && y < 0 {
                    if model.lastSelectedChar == nil {
                        model.selectedChars = []
                    }
                    model.lastSelectedChar = nil
                    model.selectedChar = nil
                    return
                }
                guard y >= 0 && y < map.count else {
                    return
                }
                let mapI = map[y]
                var x = -1
                for (_, (di, _, i)) in mapI.enumerated() {
                    if pos.x < di {
                        break
                    }
                    x = i
                }
                if x >= 0 && model.lastSelectedChar == nil {
                    let (_, ei, _) = mapI.last!
                    if pos.x > ei {
                        x = -1
                    }
                }
                if finished && x < 0 {
                    if model.lastSelectedChar == nil {
                        model.selectedChars = []
                    }
                    model.lastSelectedChar = nil
                    model.selectedChar = nil
                    return
                }
                if x < 0 {
                    return
                }
                let newCoor = IntCoordinate(x: x, y: y / 2)
                if !finished && newCoor == model.lastSelectedChar {
                    return
                }
                model.lastSelectedChar = newCoor
                if finished {
                    model.selectedChars =
                        model.selectedChar != nil ? [model.selectedChar!, newCoor] : [newCoor]
                    model.lastSelectedChar = nil
                    model.selectedChar = nil
                } else {
                    if model.selectedChar == nil {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        model.selectedChar = newCoor
                        model.selectedChars = [newCoor]
                    } else {
                        model.selectedChars = [model.selectedChar!, newCoor]
                    }
                }
            }
            let updateSelection: (Bool) -> Void = { finished in
                DispatchQueue.main.async {
                    selectedChars = model.selectedChars
                    if !finished {
                        return
                    }
                    if selectedChars.isEmpty {
                        selection = nil
                        if finished {
                            tapHandler.value.onSelection?(nil)
                        }
                    } else {
                        let chars = selectedChars.map { ($0, charMap[$0]!) }.sorted { $0.1 <= $1.1 }
                        let start = chars.first!.1
                        let end = chars.last!.1
                        let selection = String(
                            displayContent[
                                displayContent.index(
                                    displayContent.startIndex, offsetBy: start)...displayContent
                                    .index(displayContent.startIndex, offsetBy: end)]
                        )
                        self.selection = selection
                        if finished {
                            tapHandler.value.onSelection?(
                                (
                                    selection,
                                    CGRectMake(
                                        selectionRect.minX + proxy.frame(in: .global).minX,
                                        selectionRect.minY + proxy.frame(in: .global).minY,
                                        selectionRect.maxX - selectionRect.minX,
                                        selectionRect.maxY - selectionRect.minY),
                                    horizontal,
                                    {
                                        model.selectedChars = []
                                        model.selectedChar = nil
                                        model.lastSelectedChar = nil
                                        DispatchQueue.main.async {
                                            selectedChars = model.selectedChars
                                            tapHandler.value.onSelection?(nil)
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
            }
            let onDrag: (CGPoint, CGPoint, Bool) -> Void = { loc, sloc, finished in
                defer {
                    if finished {
                        model.startLocation = nil
                        model.selecting = nil
                    }
                }

                let firstSelecting = model.selecting == nil
                if firstSelecting {
                    let dx = loc.x - sloc.x
                    let dy = loc.y - sloc.y
                    let dist = sqrt(dx * dx + dy * dy)
                    model.selecting = dist < model.dist * style%!.fontSize
                }

                switch model.selecting {
                case nil:
                    return
                case .some(false):
                    if firstSelecting {
                        tapHandler.value.onDrag?(sloc, sloc, proxy.size, false)
                    }
                    tapHandler.value.onDrag?(loc, sloc, proxy.size, finished)
                    return
                case .some(true):
                    onPos(loc, finished)
                    updateSelection(finished)
                    return
                }
            }
            Canvas { context, _ in
                var actualCellColumns = cellColumns
                let maxCellColumns = chars.map { $0.1 }.max() ?? 0
                if maxCellColumns > cellColumns - normalCells {
                    actualCellColumns = maxCellColumns
                }
                let halfPadding = Double(normalCells / 2)
                var highlight = false
                var selectedChars = selectedChars
                for (j, (line, lineCells, _, _)) in chars.enumerated() {
                    let fixPadding =
                        actualCellColumns != 0 && lineCells >= actualCellColumns - normalCells
                    let cellWidth = pageWidth / Double(actualCellColumns)
                    let fx: (Int) -> Double =
                        !fixPadding
                        ? { _ in 0 }
                        : {
                            var skipPaddings = 0
                            for c in line {
                                if !nopaddingFixChars.contains(c.char) {
                                    break
                                }
                                skipPaddings += c.width
                            }
                            if skipPaddings == actualCellColumns {
                                skipPaddings = 0
                            }
                            let fxPerCell =
                                cellWidth
                                * (Double(actualCellColumns - lineCells)
                                    / Double(lineCells - skipPaddings))
                            return {
                                $0 <= skipPaddings ? 0 : fxPerCell * Double($0 - skipPaddings)
                            }
                        }()
                    map.append([])
                    map.append([])
                    for (i, c) in line.enumerated() {
                        let coor = IntCoordinate(x: i, y: j)
                        charMap[coor] = displayChars.count
                        displayChars.append(c.char)
                        if c.newLine == true {
                            displayChars.append("\n")
                        }
                        if selectedChars.contains(coor) {
                            highlight = true
                            selectedChars.remove(coor)
                        }
                        let font = c.tag == nil ? normalFont : tagFonts[c.tag!]!
                        let fontNames = font.0
                        let fontSize = font.1
                        let charFont = glyphsService.get(String(c.char), fonts: fontNames)
                        let text =
                            charFont == nil
                            ? (Text(String(missingChar%!.char)).font(
                                Font.system(size: fontSize)
                            )
                            .foregroundColor(highlight ? .white : missingChar%!.foreground))
                            : (Text(String(c.char)).font(
                                {
                                    let f = Font.custom(charFont!.0, size: fontSize)
                                    return c.half ? f.monospaced() : f
                                }()
                            ).foregroundColor(highlight ? .white : font.2))
                        let resolved = context.resolve(text)
                        let rotate = !horizontal && charOptions%!.rotates.contains(c.char)
                        let dx =
                            horizontal
                            ? (cellWidth * Double(c.x) + Double(c.width / 2) * cellWidth
                                + fx(c.x))
                            : (size.width - cellHeight * halfPadding - cellHeight * Double(c.y)
                                - Double(c.offset) * perOffset)
                        let dy =
                            horizontal
                            ? (cellHeight * halfPadding + cellHeight * Double(c.y) + Double(
                                c.offset) * perOffset)
                            : (-(rotate ? cellWidth * halfPadding : 0)
                                + cellWidth * Double(c.x) + Double(c.height / 2) * cellWidth
                                + fx(c.x))

                        let mx = cellWidth * Double(c.x) + cellWidth + fx(c.x)
                        let mex = mx + cellWidth * Double(c.width)
                        if c.offset >= 0 {
                            map[2 * j + 1].append((mx, mex, i))
                        }
                        if c.offset <= 0 {
                            map[2 * j].append((mx, mex, i))
                        }
                        context.translateBy(x: dx, y: dy)

                        if highlight {
                            let bgPad = 2.0
                            let nextChar =
                                (i != line.count - 1 && !selectedChars.isEmpty)
                                ? line[i + 1] : nil
                            let charSize = fontSize * (c.half ? 0.5 : 1)
                            let sameSubLine = nextChar?.offset == c.offset
                            var width =
                                !sameSubLine
                                ? charSize
                                : (cellWidth * Double(nextChar!.x) - cellWidth * Double(c.x)
                                    + fx(nextChar!.x) - fx(c.x))
                            width += bgPad
                            var height = fontSize + bgPad
                            var (sx, sy) = (-charSize / 2, -height / 2)
                            if !horizontal {
                                (width, height) = (height, width)
                                (sx, sy) = (sy, sx)
                            }

                            if rotate {
                                sy += cellWidth * halfPadding / 2
                            }
                            let ex = sx + width
                            let ey = sy + height
                            var p = Path()
                            p.move(to: .init(x: sx, y: sy))
                            p.addLine(to: .init(x: ex, y: sy))
                            p.addLine(to: .init(x: ex, y: ey))
                            p.addLine(to: .init(x: sx, y: ey))
                            p.addLine(to: .init(x: sx, y: sy))
                            selectionRect.minX = min(selectionRect.minX, sx + dx)
                            selectionRect.maxX = max(selectionRect.maxX, ex + dx)
                            selectionRect.minY = min(selectionRect.minY, sy + dy)
                            selectionRect.maxY = max(selectionRect.maxY, ey + dy)
                            context.fill(
                                p,
                                with: .color(
                                    Color(
                                        cgColor: .init(
                                            red: 0x2D / 0xFF, green: 0x2D / 0xFF, blue: 0x2D / 0xFF,
                                            alpha: 1))))
                        }
                        if rotate {
                            context.rotate(by: Angle(degrees: 90))
                        }
                        context.draw(
                            resolved, at: CGPoint(x: 0, y: 0),
                            anchor: rotate ? .leading : .center)
                        if rotate {
                            context.rotate(by: Angle(degrees: -90))
                        }
                        context.translateBy(x: -dx, y: -dy)

                        if highlight && selectedChars.isEmpty {
                            highlight = false
                        }
                    }
                }
                displayContent = String(displayChars)
            }.gesture(
                ExclusiveGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            let tap = model.selectedChars.isEmpty
                            if tap {
                                tapHandler.value.onTap?(value.location, proxy.size)
                            } else {
                                model.selectedChars = []
                                model.selectedChar = nil
                                model.lastSelectedChar = nil
                                updateSelection(true)
                            }
                        },
                    DragGesture(minimumDistance: 0, coordinateSpace: .local).updating(
                        $fingerLocation
                    ) {
                        (value, _, _) in
                        onDrag(value.location, value.startLocation, false)
                    }
                    .onEnded { value in
                        onDrag(value.location, value.startLocation, true)
                    }
                )
            )
        }
    }

    @State private var model = Model()

    class Model {
        var startLocation: CGPoint? = nil
        var selecting: Bool? = nil
        let diff = 0.25
        let dist = 0.25
        var selectedChar: IntCoordinate? = nil
        var lastSelectedChar: IntCoordinate? = nil
        var selectedChars: Set<IntCoordinate> = []
    }
}

extension FormattedTextV {
    static var defaultStyle: Style = {
        let font = UIFont.preferredFont(forTextStyle: .title2)
        return Style(
            fontSize: font.pointSize,
            fontNames: [(font.fontName, nil)],
            foreground: .primary)
    }()
}

extension FormattedTextV {
    struct Style: CopyWithable {
        let fontSize: Double
        var fontNames: [(String, Bool?)]
        let foreground: Color
        var lineHeight: Double = 1.4
        var charWidth: Double = 1.1
        var smallFont = (8, 6)
    }

    struct Tag: CopyWithable, MeasuredTextTag {
        var small: Bool {
            relativeSize == .small
        }

        let open: Character
        let close: Character
        var fontNames: [(String, Bool?)]? = nil
        var foreground: Color? = nil
        var relativeSize: RelativeSize = .small
    }

    struct MissingChar {
        let char: Character
        let foreground: Color
    }

    struct CharsOptions: CopyWithable {
        var map: [Character: Character] = [:]
        var anchors: [Character: UnitPoint] = [:]
        var rotates: Set<Character> = []
        var ignoreChars: Set<Character> = []
        var halfChars: Set<Character> = []
    }

    enum RelativeSize {
        case normal
        case small
    }

    enum TextDirection {
        case horizontal
        case vertical
    }
}

#if DEBUG
    extension FormattedTextV.TextDirection: CustomStringConvertible {
        var description: String {
            switch self {
            case .horizontal: return "horizontal"
            case .vertical: return "vertical"
            }
        }
    }
#endif

#Preview {
    VStack {
        FormattedTextV(
            try! String(
                contentsOfFile: Bundle.main.path(
                    forResource: "previewdata/荀子.txt", ofType: nil)!)
        )
        .background(.green.opacity(0.2))
        .padding().background(.yellow.opacity(0.2))
        //        .environmentOo(FormattedTextV.TextDirection.horizontal)
        .environmentOo(
            TagHandler().with(
                \.onTap,
                { loc, size in
                    print(loc)
                }))
    }.formattedTextEnvironments()
}
