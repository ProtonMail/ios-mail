// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CommonCrypto
import Foundation

enum AES {
    struct CryptorError: Error {
        let status: CCCryptorStatus
    }

    enum CTR {
        static func decrypt(ciphertext: Data, key: Data, iv: Data) throws(CryptorError) -> Data {
            let cryptor = try createCryptor(key: key, iv: iv)

            defer {
                CCCryptorRelease(cryptor)
            }

            return try update(cryptor: cryptor, with: ciphertext)
        }

        private static func createCryptor(key: Data, iv: Data) throws(CryptorError) -> CCCryptorRef {
            var cryptor: CCCryptorRef?

            let status = iv.withUnsafeBytes { ivBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCryptorCreateWithMode(
                        CCOperation(kCCDecrypt),
                        CCMode(kCCModeCTR),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCPadding(ccNoPadding),
                        ivBytes.baseAddress,
                        keyBytes.baseAddress,
                        key.count,
                        nil,
                        0,
                        0,
                        CCModeOptions(kCCModeOptionCTR_BE),
                        &cryptor
                    )
                }
            }

            if let cryptor {
                return cryptor
            } else {
                throw CryptorError(status: status)
            }
        }

        private static func update(cryptor: CCCryptorRef, with ciphertext: Data) throws(CryptorError) -> Data {
            var outBytes = [UInt8](repeating: 0, count: ciphertext.count)

            let status = ciphertext.withUnsafeBytes { ciphertextBytes in
                CCCryptorUpdate(
                    cryptor,
                    ciphertextBytes.baseAddress,
                    ciphertext.count,
                    &outBytes,
                    outBytes.count,
                    nil
                )
            }

            if status == kCCSuccess {
                return Data(outBytes)
            } else {
                throw CryptorError(status: status)
            }
        }
    }
}
