// !swiftlint:disable file_header
//
//  Hash.swift
//
//  Created by Mihael Isaev on 21.04.15.
//  Copyright (c) 2014 Mihael Isaev inc. All rights reserved.
//
// ***********************************************************
//
// How to import CommonCrypto in Swift project without Obj-c briging header
//
// To work around this create a directory called CommonCrypto in the root of the project using Finder.
// In this directory create a file name module.map and copy the following into the file.
// You will need to alter the paths to ensure they point to the headers on your system.
//
// module CommonCrypto [system] {
//     header "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/CommonCrypto/CommonCrypto.h"
//     export *
// }
// To make this module visible to Xcode, go to Build Settings, Swift Compiler – Search Paths
// and set Import Paths to point to the directory that contains the CommonCrypto directory.
//
// You should now be able to use import CommonCrypto in your Swift code.
//
// You have to set the Import Paths in every project that uses your framework so that Xcode can find it.
//
// ***********************************************************
//

import Foundation
import CommonCrypto

public extension String {
    var md5: String {
        return HMAC.hash(self, algo: HMACAlgo.md5)
    }

    var md5_byte: Data? {
        return HMAC.hash(self, algo: HMACAlgo.md5)
    }

    var sha1: String {
        return HMAC.hash(self, algo: HMACAlgo.sha1)
    }

    var sha224: String {
        return HMAC.hash(self, algo: HMACAlgo.sha224)
    }

    var sha256: String {
        return HMAC.hash(self, algo: HMACAlgo.sha256)
    }

    var sha384: String {
        return HMAC.hash(self, algo: HMACAlgo.sha384)
    }

    var sha512: String {
        return HMAC.hash(self, algo: HMACAlgo.sha512)
    }

    var sha512_byte: Data? {
        return HMAC.hash(self, algo: HMACAlgo.sha512)
    }
}

extension Data {
    var sha512_byte: Data {
        return HMAC.hash(self, algo: HMACAlgo.sha512)
    }
}

public struct HMAC {

    static func hash(_ inp: String, algo: HMACAlgo) -> String {
        if let stringData = inp.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return hexStringFromData(digest(stringData, algo: algo))
        }
        return ""
    }

    static func hash(_ inp: String, algo: HMACAlgo) -> Data? {
        if let stringData = inp.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return digest(stringData, algo: algo)
        }
        return nil
    }

    static func hash(_ inp: Data, algo: HMACAlgo) -> Data {
        return digest(inp, algo: algo)
    }

    fileprivate static func digest(_ input: Data, algo: HMACAlgo) -> Data {
        let digestLength = algo.digestLength()
        var hash = [UInt8](repeating: 0, count: digestLength)
        switch algo {
        case .md5:
            CC_MD5((input as NSData).bytes, UInt32(input.count), &hash)
        case .sha1:
            CC_SHA1((input as NSData).bytes, UInt32(input.count), &hash)
        case .sha224:
            CC_SHA224((input as NSData).bytes, UInt32(input.count), &hash)
        case .sha256:
            CC_SHA256((input as NSData).bytes, UInt32(input.count), &hash)
        case .sha384:
            CC_SHA384((input as NSData).bytes, UInt32(input.count), &hash)
        case .sha512:
            CC_SHA512((input as NSData).bytes, UInt32(input.count), &hash)
        }
        return Data(bytes: hash, count: digestLength)
    }

    public static func hexStringFromData(_ input: Data) -> String {
        var bytes = [UInt8](repeating: 0, count: input.count)
        (input as NSData).getBytes(&bytes, length: input.count)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}

enum HMACAlgo {
    case md5, sha1, sha224, sha256, sha384, sha512

    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .md5:
            result = CC_MD5_DIGEST_LENGTH
        case .sha1:
            result = CC_SHA1_DIGEST_LENGTH
        case .sha224:
            result = CC_SHA224_DIGEST_LENGTH
        case .sha256:
            result = CC_SHA256_DIGEST_LENGTH
        case .sha384:
            result = CC_SHA384_DIGEST_LENGTH
        case .sha512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
