//
//  ReadingBookSummaryView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/20.
//

import AppCommon
import Foundation
import SwiftUI

struct ReadingBookSummaryView: UpdatableViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    let readingBook: ReadingBook
    let inline: LiteralOnlyBool

    init(_ readingBook: ReadingBook, inline: LiteralOnlyBool = false) {
        self.readingBook = readingBook
        self.inline = inline
    }

    @State var book: File? = nil

    var forceUpdateBy: UUID? {
        readingBook.id
    }

    var updateBys: [(any Equatable)?]? {
        [book]
    }

    var updatableBody: some View {
        let _ = Self._printTrace()
        Group {
            if inline.value {
                HStack(spacing: 0) {
                    if let name = book?.name {
                        Text(name).lineLimit(1)
                        Spacer()
                    } else {
                        Text("")
                    }
                }

            } else {
                HStack {
                    Image("txt")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    Text((book?.name ?? ""))
                    if readingBook.comment != nil {
                        Text((readingBook.comment ?? "")).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 0) {
                        Image(systemName: "clock").padding(.trailing, 5)
                        Text(
                            DateFormatter.localizedString(
                                from: readingBook.accessed, dateStyle: .short, timeStyle: .none)
                        )
                    }.font(.footnote)
                }
            }
        }.onAppear {
            tryDo {
                let rep: any FilesRepository = locate()
                book = try rep.readOne(by: .id, value: readingBook.book)
            }
        }
    }
}

#Preview {
    ReadingBookSummaryView(ReadingBook.mock()).usePreviewServices()
}
