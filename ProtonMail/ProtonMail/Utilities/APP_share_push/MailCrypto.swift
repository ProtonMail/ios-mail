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
    static func getAddressKeyPassphrase(userKeys: [ArmoredKey], passphrase: Passphrase, key: Key) throws -> Passphrase {
        guard let token = key.token, let signature = key.signature else {
            return passphrase
        }

        let decryptionKeys = userKeys.map {
            DecryptionKey(privateKey: $0, passphrase: passphrase)
        }

        let plainToken: String = try Decryptor.decrypt(decryptionKeys: decryptionKeys, encrypted: .init(value: token))

        guard MailCrypto().verifyTokenFormat(decryptedToken: plainToken) else {
            throw Self.CryptoError.verificationFailed
        }

        let verification = try Sign.verifyDetached(
            signature: .init(value: signature),
            plainText: plainToken,
            verifierKeys: userKeys
        )
        if verification == true {
            return Passphrase(value: plainToken)
        } else {
            throw Self.CryptoError.verificationFailed
        }
    }

    static func decryptionKeys(
        basedOn addressKeys: [Key],
        mailboxPassword: Passphrase,
        userKeys: [ArmoredKey]
    ) -> [DecryptionKey] {
        addressKeys.compactMap { addressKey in
            let keyPassphrase: Passphrase
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
            return DecryptionKey(privateKey: ArmoredKey(value: addressKey.privateKey), passphrase: keyPassphrase)
        }
    }

    func buildPrivateKeyRing(decryptionKeys: [DecryptionKey]) throws -> CryptoKeyRing {
        let keys: [(privateKey: String, passphrase: String)] = decryptionKeys.map {
            ($0.privateKey.value, $0.passphrase.value)
        }
        return try Crypto().buildPrivateKeyRing(keys: keys)
    }

    func buildPublicKeyRing(adding armoredKeys: [ArmoredKey]) throws -> CryptoKeyRing {
        let keys: [Data] = try armoredKeys.map {
            try $0.unArmor().value
        }
        return try Crypto().buildKeyRingNonOptional(adding: keys)
    }
}

extension UnArmoredKey {
    func armor() throws -> ArmoredKey {
        var error: NSError?
        let result = ArmorArmorKey(value, &error)
        if let error = error {
            throw error
        } else {
            return ArmoredKey(value: result)
        }
    }
}
