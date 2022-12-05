//
//  Crypto.swift
//  Proton Mail - Created on 9/11/19.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import Crypto
import CryptoKit
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Log

/// Helper
class MailCrypto {

    enum CryptoError: Error {
        case failedGeneratingKeypair(Error?)
        case verificationFailed
        case decryptionFailed
    }

    private let EXPECTED_TOKEN_LENGTH: Int = 64

    // MARK: - Message

    func verifyDetached(signature: String, plainText: String, binKeys: [Data]) throws -> Bool {
        var error: NSError?

        guard let publicKeyRing = buildPublicKeyRing(keys: binKeys) else {
            return false
        }

        let plainMessage = CryptoNewPlainMessageFromString(plainText)
        let signature = CryptoNewPGPSignatureFromArmored(signature, &error)
        if let err = error {
            throw err
        }

        do {
            try publicKeyRing.verifyDetached(plainMessage, signature: signature, verifyTime: CryptoGetUnixTime())
            return true
        } catch {
            return false
        }
    }

    /**
     * Check that the key token is a 32 byte value encoded in hexadecimal form.
     */
    private func verifyTokenFormat(decryptedToken: String) -> Bool {
        decryptedToken.count == EXPECTED_TOKEN_LENGTH && decryptedToken.allSatisfy { $0.isHexDigit }
    }

    // MARK: - static

    static func updateTime( _ time: Int64, processInfo: SystemUpTimeProtocol? = nil) {
        if var processInfo = processInfo {
            processInfo.updateLocalSystemUpTime(time: processInfo.systemUpTime)
            processInfo.localServerTime = TimeInterval(time)
        }
        CryptoUpdateTime(time)
    }

    func buildPublicKeyRing(keys: [Data]) -> CryptoKeyRing? {
        var error: NSError?
        let newKeyRing = CryptoNewKeyRing(nil, &error)
        guard let keyRing = newKeyRing else {
            return nil
        }
        for key in keys {
            do {
                guard let keyToAdd = CryptoNewKey(key, &error) else {
                    continue
                }
                guard keyToAdd.isPrivate() else {
                    try keyRing.add(keyToAdd)
                    continue
                }
                guard let publicKeyData = try? keyToAdd.getPublicKey() else {
                    continue
                }
                var error: NSError?
                let publicKey = CryptoNewKey(publicKeyData, &error)
                if let error = error {
                    throw error
                } else {
                    try keyRing.add(publicKey)
                }
            } catch {
                continue
            }
        }
        return keyRing
    }

    static func generateRandomKeyPair() throws -> (passphrase: String, publicKey: String, privateKey: String) {
        let passphrase = UUID().uuidString
        let username = UUID().uuidString
        let domain = "protonmail.com"
        let email = "\(username)@\(domain)"
        let keyType = "x25519"
        var error: NSError?

        guard let unlockedKey = CryptoGenerateKey(username, email, keyType, 0, &error) else {
            throw CryptoError.failedGeneratingKeypair(error)
        }

        let cryptoKey = try unlockedKey.lock(passphrase.data(using: .utf8))
        unlockedKey.clearPrivateParams()

        let publicKey = cryptoKey.getArmoredPublicKey(&error)
        if let concreteError = error {
            throw CryptoError.failedGeneratingKeypair(concreteError)
        }
        let privateKey = cryptoKey.armor(&error)
        if let concreteError = error {
            throw CryptoError.failedGeneratingKeypair(concreteError)
        }

        return (passphrase, publicKey, privateKey)
    }

    // Extracts the right passphrase for migrated/non-migrated keys and verifies the signature
    static func getAddressKeyPassphrase(userKeys: [Data], passphrase: Passphrase, key: Key) throws -> Passphrase {
        guard let token = key.token, let signature = key.signature else {
            return passphrase
        }

        let plainToken = try token.decryptMessageNonOptional(binKeys: userKeys, passphrase: passphrase.value)

        guard MailCrypto().verifyTokenFormat(decryptedToken: plainToken) else {
            throw Self.CryptoError.verificationFailed
        }

        let verification = try MailCrypto().verifyDetached(signature: signature,
                                                           plainText: plainToken,
                                                           binKeys: userKeys)
        if verification == true {
            return Passphrase(value: plainToken)
        } else {
            throw Self.CryptoError.verificationFailed
        }
    }

    static func keysWithPassphrases(
        basedOn addressKeys: [Key],
        mailboxPassword: Passphrase,
        userKeys: [Data]?
    ) -> [(privateKey: String, passphrase: String)] {
        addressKeys.compactMap { addressKey in
            let keyPassphrase: Passphrase
            if let userKeys = userKeys {
                do {
                    keyPassphrase = try getAddressKeyPassphrase(
                        userKeys: userKeys,
                        passphrase: mailboxPassword,
                        key: addressKey
                    )
                } catch {
                    // do not propagate the error, perhaps other keys are still OK, so we should proceed
                    PMLog.error(error)
                    return nil
                }
            } else {
                keyPassphrase = mailboxPassword
            }
            return (addressKey.privateKey, keyPassphrase.value)
        }
    }

}
