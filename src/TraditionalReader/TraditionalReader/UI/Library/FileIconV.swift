//
//  BookThumbV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/22.
//

import AppCommon
import Foundation
import SwiftUI

extension File {
    var isFolder: Bool {
        self.type == .branch
    }

    var fileIcon: String {
        (self.isFolder || self.fileType == .none) ? "folder" : self.fileType.rawValue
    }
}

public struct FileIconV: View {
    let name: String
    let path: String?
    let isFolder: Bool
    let fileType: String
    let highlight: Bool

    init(_ book: File, highlight: Bool = false) {
        name = book.name
        path = book.path
        isFolder = book.isFolder
        fileType = book.fileIcon
        self.highlight = highlight
    }

    public var body: some View {
        let _ = Self._printTrace()
        ZStack {
            VStack {
                Spacer()
                Image(fileType)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                Text(name).padding(.vertical, 5).lineLimit(1)
            }.padding(5).background(highlight ? Color.secondary : Color.transparent)
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5)))
        }
    }
}

#Preview {
    LazyVGrid(
        columns: [
            GridItem(.adaptive(minimum: 80))
        ], spacing: 20
    ) {
        FileIconV(
            File.mock().with(\.path, "..").with(\.type, .branch)
        )
        FileIconV(
            File.mock().with(\.path, "/图书/路径").with(\.type, .branch)
        )
        FileIconV(
            File.mock().with(\.path, "/图书/路径").with(\.type, .leaf)
        )
    }
    .padding(.horizontal)
}
