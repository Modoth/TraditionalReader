//
//  TxtPageV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/27.
//

import AppCommon
import SwiftUI

struct TxtPageV: View {
    static let fontStyle: FormattedTextV.Style = {
        let font = UIFont.preferredFont(
            forTextStyle: UIDevice.current.userInterfaceIdiom == .pad ? .title1 : .title2)
        return FormattedTextV.Style(
            fontSize: font.pointSize,
            fontNames: [
                "TW-Kai", "TW-Kai-Ext-B", "TW-Kai-Plus",
            ].map { ($0, nil) },
            foreground: Color.red.opacity(0.8),
            smallFont: (8, 6))
    }()
    static let tags: [Character: FormattedTextV.Tag] = [:]
    @EnvironmentObject var textDirection: OO<FormattedTextV.TextDirection>
    let content: String
    let title: String
    let chapter: String?
    let page: Int
    let totalPage: Int?
    let vertical: Bool
    let font: Font
    let fontSize: Double
    let lineHeight = 1.5
    let charWidth = 1.1
    //    let borderOuter = 2.0
    let borderInner = 1.0
    //    let borderGap = 4.0
    let outerGridColor = Color.red.opacity(0.8)
    let innerGridColor = Color.red.opacity(0.8)
    let foreground = Color.black.opacity(0.8)
    let titleScale = 0.8
    let titleForeground = Color.red.opacity(0.8)
    let txtPad = 10.0
    let onSize: ((Int, Int) -> Void)?
    let width: Int?
    let height: Int?
    let pageSide: FileReaderPageSide
    init(
        _ content: String,
        title: String, chapter: String?, page: Int, totalPage: Int?,
        pageSide: FileReaderPageSide = .none,
        fontSize: Double,
        font: Font = .footnote,
        width: Int? = nil,
        height: Int? = nil,
        vertical: Bool = false,
        onSize: ((Int, Int) -> Void)? = nil
    ) {
        self.content = content
        self.title = title
        self.chapter = chapter
        self.page = page
        self.totalPage = totalPage
        self.vertical = vertical
        self.fontSize = fontSize
        self.font = font
        self.width = width
        self.height = height
        self.onSize = onSize
        self.pageSide = pageSide
    }
    var body: some View {
        let _ = Self._printTrace()
        GeometryReader { proxy in
            ZStack {
                let borderGap = Double(Int(fontSize / 6))
                let borderOuter = Double(Int(fontSize / 8))
                let rightPage: Bool = pageSide == .right
                let size: (Double, Double) =
                    vertical
                    ? (proxy.size.height, proxy.size.width) : (proxy.size.width, proxy.size.height)
                let paddingPerFont = 1
                let gridByGeo = (
                    Int(size.0 / (fontSize * self.charWidth)),
                    Int(size.1 / (fontSize * self.lineHeight))
                )
                if onSize != nil {
                    let _ = onSize!(
                        max(gridByGeo.0 - paddingPerFont, 1), max(gridByGeo.1 - paddingPerFont, 1))
                } else {
                    let width = self.width ?? gridByGeo.0
                    let height = self.height ?? gridByGeo.1
                    let gridWidth = width + paddingPerFont
                    let gridHeight = height + paddingPerFont

                    let charWidth = size.0 / Double(gridWidth)
                    let lineHeight = size.1 / Double(gridHeight)

                    let padding_ = (
                        charWidth * CGFloat(paddingPerFont) / 2,
                        lineHeight * CGFloat(paddingPerFont) / 2
                    )
                    let padding = vertical ? (padding_.1, padding_.0) : padding_

                    let verticalPaddingFix = 2.0

                    Rectangle().foregroundColor(.transparent).border(
                        outerGridColor, width: borderOuter,
                        edges: rightPage ? [.top, .bottom, .trailing] : [.top, .bottom, .leading]
                    )
                    .padding(
                        rightPage ? .trailing : .leading,
                        padding.0 - borderOuter - borderGap - borderInner
                    )
                    .padding(.vertical, padding.1 - borderOuter - borderGap - borderInner)

                    HStack {
                        if !rightPage {
                            Spacer()
                        }
                        HStack {
                            FormattedTextV("︻\(title)︼")
                        }.padding(.vertical, padding.1 + verticalPaddingFix - borderOuter)
                            .frame(width: lineHeight * 1.1)
                            .offset(x: (rightPage ? -1 : 1) * lineHeight / 2, y: 0)
                            .clipped()
                            .padding(.horizontal, 1)
                            .clipped()
                            .padding(.vertical, borderOuter)
                        if rightPage {
                            Spacer()
                        }
                    }
                    .environmentOo(
                        Self.fontStyle
                    )
                    .environmentOo(Self.tags)

                    HStack {
                        ZStack {
                            if vertical {
                                HStack {
                                    ForEach(0...height, id: \.self) { i in
                                        HStack {
                                            Rectangle().fill(innerGridColor).frame(
                                                width: 1, alignment: .center)
                                            if i != height {
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                            VStack {
                                FormattedTextV(content)
                                    .with(\.columns, width)
                                    .with(\.rows, height)
                            }.padding(.vertical, verticalPaddingFix)
                                .border(innerGridColor, width: 1, edges: [.top, .bottom])
                        }
                    }.padding(.horizontal, padding.0)
                        .padding(.vertical, padding.1)
                }
            }.environmentOo(
                vertical
                    ? FormattedTextV.TextDirection.vertical
                    : FormattedTextV.TextDirection.horizontal)
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        TxtPageV(
            try! String(
                contentsOfFile: Bundle.main.path(
                    forResource: "previewdata/荀子.txt", ofType: nil)!),
            title: "欽定四庫全書總目", chapter: "經部總敘", page: 1, totalPage: 125, pageSide: .left,
            fontSize: 22,
            vertical: true
        ).frame(width: .infinity)
        TxtPageV(
            try! String(
                contentsOfFile: Bundle.main.path(
                    forResource: "previewdata/荀子.txt", ofType: nil)!),
            title: "欽定四庫全書總目", chapter: "經部總敘", page: 1, totalPage: 125, pageSide: .none,
            fontSize: 22,
            vertical: true
        ).frame(width: .infinity)
    }.formattedTextEnvironments()
}
