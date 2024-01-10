//
//  ripemd128.swift
//  AppCommon
//
//  Created by zxq on 2023/11/15.
//  Translated from web content.
//

import Foundation

private func rotl(_ x: UInt32, _ n: UInt32) -> UInt32 {
    return (x >> (32 - n)) | (x << n)
}

private let S: [[UInt32]] = [
    [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8],  // round 1
    [7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12],  // round 2
    [11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5],  // round 3
    [11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12],  // round 4
    [8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6],  // parallel round 1
    [9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11],  // parallel round 2
    [9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5],  // parallel round 3
    [15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8],  // parallel round 4
]

private let X: [[UInt32]] = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],  // round 1
    [7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8],  // round 2
    [3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12],  // round 3
    [1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2],  // round 4
    [5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12],  // parallel round 1
    [6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2],  // parallel round 2
    [15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13],  // parallel round 3
    [8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14],  // parallel round 4
]

private let K: [UInt32] = [
    0x0000_0000,  // FF
    0x5a82_7999,  // GG
    0x6ed9_eba1,  // HH
    0x8f1b_bcdc,  // II
    0x50a2_8be6,  // III
    0x5c4d_d124,  // HHH
    0x6d70_3ef3,  // GGG
    0x0000_0000,  // FFF
]

private let F: [(UInt32, UInt32, UInt32) -> UInt32] = [
    { (x: UInt32, y: UInt32, z: UInt32) in
        return (x ^ y ^ z)
    },
    { (x: UInt32, y: UInt32, z: UInt32) in
        return (x & y) | ((~x) & z)
    },
    { (x: UInt32, y: UInt32, z: UInt32) in
        return (x | (~y)) ^ z
    },
    { (x: UInt32, y: UInt32, z: UInt32) in
        return (x & z) | (y & (~z))
    },
]

public func ripemd128(data originalData: [UInt8]) -> [UInt8] {
    var aa: UInt32 = 0
    var bb: UInt32 = 0
    var cc: UInt32 = 0
    var dd: UInt32 = 0
    var aaa: UInt32 = 0
    var bbb: UInt32 = 0
    var ccc: UInt32 = 0
    var ddd: UInt32 = 0

    var hash: [UInt32] = [0x6745_2301, 0xefcd_ab89, 0x98ba_dcfe, 0x1032_5476]
    var bytes = originalData.count
    var padding: [UInt8] = Array(repeating: 0, count: ((bytes % 64) < 56 ? 56 : 120) - (bytes % 64))
    padding[0] = 0x80
    let paddedData: [UInt8] = originalData + padding
    let data = paddedData.withUnsafeBufferPointer {
        $0.withMemoryRebound(to: UInt32.self) {
            Array($0)
        }
    }
    bytes = bytes << 3
    let x: [UInt32] = data + [UInt32(bytes), (UInt32(bytes) >> 31) >> 1]
    var i = 0
    var t = 0
    let l = x.count
    while i < l {
        aa = hash[0]
        aaa = aa
        bb = hash[1]
        bbb = bb
        cc = hash[2]
        ccc = cc
        dd = hash[3]
        ddd = dd
        while t < 64 {
            let r: Int = ~(~(t / 16))
            aa = rotl(aa &+ F[r](bb, cc, dd) &+ x[i + Int(X[r][t % 16])] &+ K[r], S[r][t % 16])
            let tmp = dd
            dd = cc
            cc = bb
            bb = aa
            aa = tmp
            t += 1
        }
        while t < 128 {
            let r = ~(~(t / 16))
            let rr = ~(~((63 - (t % 64)) / 16))
            aaa = rotl(
                aaa &+ F[rr](bbb, ccc, ddd) &+ x[i + Int(X[r][t % 16])] &+ K[r], S[r][t % 16])

            let tmp = ddd
            ddd = ccc
            ccc = bbb
            bbb = aaa
            aaa = tmp

            t += 1
        }

        ddd = hash[1] &+ cc &+ ddd
        hash[1] = hash[2] &+ dd &+ aaa
        hash[2] = hash[3] &+ aa &+ bbb
        hash[3] = hash[0] &+ bb &+ ccc
        hash[0] = ddd

        i += 16
        t = 0
    }
    return hash.withUnsafeBufferPointer {
        $0.withMemoryRebound(to: UInt8.self) {
            Array($0)
        }
    }
}
