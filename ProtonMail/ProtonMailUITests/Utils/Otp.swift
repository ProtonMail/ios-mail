//
//  Base32.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 21.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import CryptoKit

class Otp {
    
    func generate(_ secret32: String) -> String {
        if #available(iOS 13.0, *) {
            let period = TimeInterval(30)
            let digits = 6
            let secret = Base32Decode(data: secret32)
            var counter = UInt64(Date().timeIntervalSince1970 / period).bigEndian
            let counterData = withUnsafeBytes(of: &counter) { Array($0) }
            let hash = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: SymmetricKey(data: secret))
            var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
               let offset = ptr[hash.byteCount - 1] & 0x0f
               let truncatedHashPtr = ptr.baseAddress! + Int(offset)
               return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
            }
            truncatedHash = UInt32(bigEndian: truncatedHash)
            truncatedHash = truncatedHash & 0x7FFF_FFFF
            truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))
            return String(format: "%0*u", digits, truncatedHash)
        } else {
            return ""
        }
    }

    private func Base32Decode(data: String) -> Data {
        let characters = [ "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "2", "3", "4", "5", "6", "7"]
        let __ = 255
        let alphabet = [
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x00 - 0x0F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x10 - 0x1F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x20 - 0x2F
            __,__,26,27, 28,29,30,31, __,__,__,__, __, 0,__,__,  // 0x30 - 0x3F
            __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x40 - 0x4F
            15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x50 - 0x5F
            __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x60 - 0x6F
            15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x70 - 0x7F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x80 - 0x8F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x90 - 0x9F
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xA0 - 0xAF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xB0 - 0xBF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xC0 - 0xCF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xD0 - 0xDF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xE0 - 0xEF
            __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xF0 - 0xFF
        ]
        return Base32Decode(data: data, alphabet: alphabet, characters: characters)!
    }

    private func Base32Decode(data: String, alphabet: Array<Int>, characters: Array<String>) -> Data? {
        var processingData = ""
        
        for char in data.uppercased() {
            let str = String(char)
            
            if characters.contains(str) {
                processingData += str
            } else if !characters.contains(str) && str != "=" {
                return nil
            }
        }
        
        if let base32Data = processingData.data(using: String.Encoding.ascii, allowLossyConversion: false) {
            // how much space do we need
            let fullGroups = base32Data.count / 8
            var bytesInPartialGroup: Int = 0
            switch base32Data.count % 8 {
            case 0:
                bytesInPartialGroup = 0
            case 2:
                bytesInPartialGroup = 1
            case 4:
                bytesInPartialGroup = 2
            case 5:
                bytesInPartialGroup = 3
            case 7:
                bytesInPartialGroup = 4
            default:
                return nil
            }
            let totalNumberOfBytes = fullGroups * 5 + bytesInPartialGroup
            
            // allocate a buffer big enough for our decode
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: totalNumberOfBytes)

            var base32Bytes = [UInt8](repeating: 0, count: base32Data.count)
            base32Data.copyBytes(to: &base32Bytes, count: base32Bytes.count)
            
            var decodedByteIndex = 0;
            for byteIndex in stride(from: 0, to: base32Data.count, by: 8) {
                let maxOffset = (byteIndex + 8 >= base32Data.count) ? base32Data.count : byteIndex + 8
                let numberOfBytes = maxOffset - byteIndex
                
                var encodedByte0: UInt8 = 0
                var encodedByte1: UInt8 = 0
                var encodedByte2: UInt8 = 0
                var encodedByte3: UInt8 = 0
                var encodedByte4: UInt8 = 0
                var encodedByte5: UInt8 = 0
                var encodedByte6: UInt8 = 0
                var encodedByte7: UInt8 = 0
                
                switch numberOfBytes {
                case 8:
                    encodedByte7 = UInt8(alphabet[Int( base32Bytes[byteIndex + 7] )])
                    fallthrough
                case 7:
                    encodedByte6 = UInt8(alphabet[Int( base32Bytes[byteIndex + 6] )])
                    fallthrough
                case 6:
                    encodedByte5 = UInt8(alphabet[Int( base32Bytes[byteIndex + 5] )])
                    fallthrough
                case 5:
                    encodedByte4 = UInt8(alphabet[Int( base32Bytes[byteIndex + 4] )])
                    fallthrough
                case 4:
                    encodedByte3 = UInt8(alphabet[Int( base32Bytes[byteIndex + 3] )])
                    fallthrough
                case 3:
                    encodedByte2 = UInt8(alphabet[Int( base32Bytes[byteIndex + 2] )])
                    fallthrough
                case 2:
                    encodedByte1 = UInt8(alphabet[Int( base32Bytes[byteIndex + 1] )])
                    fallthrough
                case 1:
                    encodedByte0 = UInt8(alphabet[Int( base32Bytes[byteIndex + 0] )])
                    fallthrough
                default:
                    break;
                }
                
                buffer[decodedByteIndex + 0] = ((encodedByte0 << 3) & 0xF8) | ((encodedByte1 >> 2) & 0x07)
                buffer[decodedByteIndex + 1] = ((encodedByte1 << 6) & 0xC0) | ((encodedByte2 << 1) & 0x3E) | ((encodedByte3 >> 4) & 0x01)
                buffer[decodedByteIndex + 2] = ((encodedByte3 << 4) & 0xF0) | ((encodedByte4 >> 1) & 0x0F)
                buffer[decodedByteIndex + 3] = ((encodedByte4 << 7) & 0x80) | ((encodedByte5 << 2) & 0x7C) | ((encodedByte6 >> 3) & 0x03)
                buffer[decodedByteIndex + 4] = ((encodedByte6 << 5) & 0xE0) | (encodedByte7 & 0x1F)
                
                decodedByteIndex += 5
            }
            
            return Data(bytesNoCopy: buffer, count: totalNumberOfBytes, deallocator: .free)
        }
        return nil
    }
}
