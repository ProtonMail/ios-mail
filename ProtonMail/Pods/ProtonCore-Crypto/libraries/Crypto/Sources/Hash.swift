//
//  Hash.swift
//  ProtonCore-Crypto - Created on 07/19/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import CommonCrypto
import ProtonCore_Utilities

public struct Hashable<Type> {
    public init(value: Type) {
        self.value = value
    }
    public let value: Type
}

public typealias HashableString = Hashable<String>
public typealias HashableData = Hashable<Data>

public enum HashError: Error {
    case stringToDataFailed
}

extension Hashable where Type == String {
    public func hmacSHA256(key: String) throws -> String {
        guard let stringData = self.value.utf8 else {
            throw HashError.stringToDataFailed
        }
        guard let keyData = key.utf8 else {
            throw HashError.stringToDataFailed
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyData.withUnsafeBytes { keyPointer in
            stringData.withUnsafeBytes { strPointer in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyPointer.baseAddress,
                       keyData.count,
                       strPointer.baseAddress,
                       stringData.count,
                       &digest)
            }
        }
        let hmac = digest.compactMap { String(format: "%02x", $0) }.joined()
        return hmac
    }
}

extension Hashable where Type == Data {
    public func hashSha256() -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = self.value.withUnsafeBytes {
            CC_SHA256($0.baseAddress, UInt32(self.value.count), &digest)
        }
        return Data(digest)
    }
}
