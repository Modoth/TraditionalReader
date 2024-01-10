//
//  AppScreen.swift
//  TraditionalReader
//
//  Created by zxq on 2023/9/19.
//

import Foundation
import SwiftUI

enum AppScreen: String, Codable, Hashable, Identifiable, CaseIterable {
    case reading
    case library
    case notes
    case setting

    var id: AppScreen { self }
}

extension AppScreen {
    @ViewBuilder
    var label: some View {
        switch self {
        case .reading:
            Label("Reading", systemImage: "book")
        case .library:
            Label("Library", systemImage: "books.vertical")
        case .notes:
            Label("Notes", systemImage: "note.text")
        case .setting:
            Label("Setting", systemImage: "gearshape")
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .reading:
            ReadingView()
        case .library:
            LibraryView()
        case .notes:
            NotesView()
        case .setting:
            SettingView()
        }
    }
}
