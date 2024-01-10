//
//  FileReaderPageV.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/23.
//

import AppCommon
import Foundation
import SwiftUI

protocol FileReaderPageView: View {
    init(
        page: FileReaderPage,
        pager: AnyObject?,
        onPager: ((BookReaderPager) -> Void)?,
        onClick: (() -> Void)?
    )
}

struct UnsupportedReaderView: View, FileReaderPageView {
    init(
        page: FileReaderPage,
        pager: AnyObject?,
        onPager: ((BookReaderPager) -> Void)?,
        onClick: (() -> Void)?
    ) {

    }

    var body: some View {
        let _ = Self._printTrace()
        Text("Unsupported")
    }
}
