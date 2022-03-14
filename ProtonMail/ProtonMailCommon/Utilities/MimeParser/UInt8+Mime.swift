//
//  UInt8+Mime.swift
//  Marcel
//
//  Created by Ben Gottlieb on 9/1/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

extension UInt8 {
    init?(asciiChar: UInt8) {
        let zero = UInt8(firstCharacterOf: "0")
        let nine = UInt8(firstCharacterOf: "9")
        let a = UInt8(firstCharacterOf: "a")
        let f = UInt8(firstCharacterOf: "f")
        let A = UInt8(firstCharacterOf: "A")
        let F = UInt8(firstCharacterOf: "F")

        if asciiChar >= zero && asciiChar <= nine { self = asciiChar - zero } else if asciiChar >= a && asciiChar <= f { self = 10 + asciiChar - a } else if asciiChar >= A && asciiChar <= F { self = 10 + asciiChar - A } else { return nil }
    }
    init?(asciiChar: UInt8, and second: UInt8) {
        if let b1 = UInt8(asciiChar: asciiChar), let b2 = UInt8(asciiChar: second) {
            self = b1 * 16 + b2
        } else {
            return nil
        }
    }
}

extension UInt8 {
    init(firstCharacterOf string: String) {
        self = UInt8(string.utf8.first!)
    }
}

extension UInt8 {
    init?(bytes: [UInt8]) {
        if bytes.count == 2 { self = bytes[0] << 4 + bytes[1] } else { return nil }
    }
}

extension UInt32 {
    init?(decimalBytes bytes: [UInt8]) {
        if bytes.count == 1 {
            self = UInt32(bytes[1])
        } else if bytes.count == 2 {
            self = UInt32(bytes[0]) * 10 + UInt32(bytes[1])
        } else if bytes.count == 4 {
            self = UInt32(bytes[0]) * 1000 + UInt32(bytes[1]) * 100 + UInt32(bytes[2]) * 10 + UInt32(bytes[3])
        } else {
            return nil
        }
    }

    init?(hexBytes bytes: [UInt8]) {
        if bytes.count == 1 { self = UInt32(bytes[0]) }
        if bytes.count == 2 { self = UInt32(bytes[0]) << 4 + UInt32(bytes[1]) } else if bytes.count == 4 { self = UInt32(bytes[0]) << 12 + UInt32(bytes[1]) << 8 + UInt32(bytes[2]) << 4 + UInt32(bytes[3]) } else { return nil }
    }
}
