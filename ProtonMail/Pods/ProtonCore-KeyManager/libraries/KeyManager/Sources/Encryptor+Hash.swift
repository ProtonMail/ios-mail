//
//  Encryptor+Hash.swift
//  ProtonCore-KeyManager - Created on 03/04/2021.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreCryptoGoInterface
import CommonCrypto

extension Encryptor.HashableString {
    public func hmacSHA256(key: String) -> String {
        let stringData = Data(self.utf8) as Encryptor.HashableData
        let keyData = Data(key.utf8)
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

extension Encryptor.HashableData {
    func hashSha256() -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        _ = self.withUnsafeBytes {
            CC_SHA256($0.baseAddress, UInt32(self.count), &digest)
        }

        return Data(digest)
    }
}
