//
//  FormattedText+.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/18.
//

import AppCommon
import Foundation
import SwiftUI

extension View {
    public func formattedTextEnvironments() -> some View {
        self.environmentOo(
            FormattedTextV.defaultStyle
                .with(
                    \.fontNames,
                    ["TW-Kai", "TW-Kai-Ext-B", "TW-Kai-Plus"].map {
                        ($0, nil)
                    })
            //                .with(\.fontNames, ["kx"].map { ($0, nil) })

        )
        .environmentOo(
            FormattedTextV.CharsOptions()
                .with(
                    \.map,
                    [
                        "“": "﹃",
                        "”": "﹄",
                        "‘": "﹁",
                        "’": "﹂",
                    ]
                )
                .with(
                    \.anchors,
                    Dictionary(uniqueKeysWithValues: "。.，,、；;".map { ($0, .topTrailing) })
                )
                .with(
                    \.rotates,
                    Set(
                        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789([{<『【「《>}])》」】』'\"？?！!：:"
                    )
                )
                .with(
                    \.halfChars,
                    Set(
                        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 "
                    ))
        )
        .environmentOo(FormattedTextV.TextDirection.vertical)
        .environmentOo(FormattedTextV.MissingChar(char: "□", foreground: .accentColor))
        .environmentOo(
            Dictionary(
                uniqueKeysWithValues: [
                    FormattedTextV.Tag(open: "【", close: "】").with(\.foreground, .purple),
                    FormattedTextV.Tag(open: "（", close: "）").with(\.foreground, .green),
                ].map { ($0.open, $0) })
        )
        .environmentOo(
            TagHandler().with(
                \.onTap,
                { loc, size in
                    print(loc)
                })
        )
        .useServices { s in
            s.register(factory: TxtMeasurer$)
        }
    }
}
