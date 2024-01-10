//
//  TestView.swift
//  TraditionalReader
//
//  Created by zxq on 2023/10/18.
//

#if DEBUG

    import SwiftUI
    import AppCommon

    struct TestView: View {
        @State var value: Double? = 0
        var body: some View {
            //            DictsView(key: .constant("君"))
            //                .background(.background)
            //                .clipShape(RoundedRectangle(cornerRadius: 10))
            //                .shadow(radius: 5)
            //                .padding()
            //                .aspectRatio(297 / 210, contentMode: .fit)
            //                .usePreviewServices()
            Text("")
        }
    }

    #Preview {
        TestView()
    }

#endif
