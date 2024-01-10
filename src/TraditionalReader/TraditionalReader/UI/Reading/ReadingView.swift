//
//  ReadingView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/21.
//

import AppCommon
import SwiftUI

struct ReadingView: ViewBase {
    @EnvironmentObject var servicesLocator: OO<ServicesLocator>
    @EnvironmentObject var notifyServices: NotifyService

    static let recentCount: LiteralOnlyInt = 4

    var body: some View {
        let _ = Self._printTrace()
        NavigationStack {
            ScrollView {
                navigatableCard("Recent Reading") { fullscreen in
                    RecentReadingView(
                        fullscreen: fullscreen,
                        maxCount: fullscreen |?| nil <> Self.recentCount)
                }

                navigatableCard("Reading Lists") { fullscreen in
                    ReadingListsView(fullscreen: fullscreen)
                }

                navigatableCard("Recent Adding") { fullscreen in
                    RecentAddingBooksView(fullscreen: fullscreen)
                }
            }
            .navigationTitle("Reading")
        }
    }

    @ViewBuilder
    private func navigatableCard(
        _ label: LocalizedStringKey, content: (LiteralOnlyBool) -> some View
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(label).font(.title3.bold())
                Spacer()
                NavigationLink(destination: {
                    content(true).navigationTitle(label)
                }) {
                    Text("All")
                    Image(systemName: "chevron.right")
                }.font(.footnote)
            }.padding([.horizontal, .top])
            content(false)
        }
    }
}

#Preview {
    ReadingView().usePreviewServices()
}
