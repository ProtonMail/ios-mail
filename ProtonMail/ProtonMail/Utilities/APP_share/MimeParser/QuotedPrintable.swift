//
//  quotedprintable.swift
//  unchained
//
//  Created by Johannes Schriewer on 13/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

extension UInt8 {
    func hexString(padded: Bool = true) -> String {
        let dict: [Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]
        var result = ""

        let c1 = Int(self >> 4)
        let c2 = Int(self & 0xf)

        if c1 == 0 && padded {
            result.append(dict[c1])
        } else if c1 > 0 {
            result.append(dict[c1])
        }
        result.append(dict[c2])

        if result.count == 0 {
            return "0"
        }
        return result
    }
}

/// Quoted printable encoder and decoder
class QuotedPrintable {

    /// Encode a string in quoted printable encoding
    ///
    /// - parameter string: String to encode
    /// - returns: quoted printable encoded string
    class func encode(string: String) -> String {
        var gen = string.utf8.makeIterator()
        var charCount = 0

        var result = ""
        result.reserveCapacity(string.count)

        while let c = gen.next() {
            switch c {
            case 32...60, 62...126:
                charCount += 1
                result.append(String(UnicodeScalar(c)))
            case 13:
                continue
            case 10:
                if result.last == " " || result.last == "\t" {
                    result.append("=\r\n")
                    charCount = 0
                } else {
                    result.append("\r\n")
                    charCount = 0
                }
            default:
                if charCount > 72 {
                    result.append("=\r\n")
                    charCount = 0
                }
                result.append(String(UnicodeScalar(61)))
                result.append(c.hexString().uppercased())
                charCount += 3
            }

            if charCount == 75 {
                charCount = 0
                result.append("=\r\n")
            }
        }

        return result
    }
}
