//
//  TagHandler.swift
//  TraditionalReader
//
//  Created by zxq on 2023/11/3.
//

import AppCommon
import Foundation
import SwiftUI

class TagHandler: ObservableObject, CopyWithable {
    var onTap: ((CGPoint, CGSize) -> Void)? = nil
    var onDrag: ((CGPoint, CGPoint, CGSize, Bool) -> Void)? = nil
    var onSelection: (((String, CGRect, Bool, () -> Void)?) -> Void)? = nil
}
