//
//  Util.swift
//  AppCommon
//
//  Created by zxq on 2023/11/24.
//

import Foundation

public let isBigEndian = CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderBigEndian.rawValue)
