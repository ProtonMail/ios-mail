//
//  CryptoManager.swift
//  ProtonCore-KeyManager - Created on 2020/11/13
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
import ProtonCoreUtilities

enum CryptoManagerCryptoError: Error {
    case privateKeyDecryptionFailed
    case KeyRingDecryptionFailed
    case calendarKeyGenerationFailed
}

@available(*, deprecated, message: "please to use ProtonCore-Crypto module find the replacements")
public enum CryptoManager {

    public static func generateCryptoKeyRing(key: String, passphrase: String) throws -> CryptoKeyRing {
        let keyring: CryptoKeyRing

        do {
            var error: NSError?
            let newKey = CryptoGo.CryptoNewKeyFromArmored(key, &error)
            if let err = error {
                throw err
            }

            guard let key = newKey else {
                throw CryptoManagerCryptoError.privateKeyDecryptionFailed
            }

            let passSlic = passphrase.data(using: .utf8)
            let unlockedKey = try key.unlock(passSlic)

            let privateKeyRing = CryptoGo.CryptoNewKeyRing(unlockedKey, &error)
            if let err = error {
                throw err
            }

            guard let _privateKeyRing = privateKeyRing else {
                throw CryptoManagerCryptoError.KeyRingDecryptionFailed
            }

            keyring = _privateKeyRing
        } catch let error as NSError {
            throw error
        }

        return keyring
    }

    @available(*, deprecated, message: "CryptoKeyRing is not needed, use getKey(key:passphrase:)")
    public static func getKey(to _: CryptoKeyRing, key: String, passphrase: String) throws -> CryptoKey {
      try getKey(key: key, passphrase: passphrase)
    }

    public static func getKey(key: String, passphrase: String) throws -> CryptoKey {
        do {
            var error: NSError?
            let newKey = CryptoGo.CryptoNewKeyFromArmored(key, &error)
            if let err = error {
                throw err
            }

            guard let key = newKey else {
                throw CryptoManagerCryptoError.privateKeyDecryptionFailed
            }

            let passSlic = passphrase.data(using: .utf8)
            let unlockedKey = try key.unlock(passSlic)

            return unlockedKey
        } catch let error as NSError {
//            DDLogDebug("addKey to CryptoKeyRing error \(error)")
            throw error
        }
    }

    /**
     Decrypt string without verifying the signature

     String to Data:
     Data(base64Encoded: keyPacket, options: .init(rawValue: 0))
     */
    public static func decryptString(keyPacket: Data, encryptedPacket: Data, keyRing: CryptoKeyRing, error: inout NSError?) -> String {
        CryptoGo.HelperDecryptAttachment(keyPacket,
                                         encryptedPacket,
                                         keyRing,
                                         &error)?.getString() ?? ""
    }

    public static func verifyDetached(signature: String, plainText: String, keyRing: CryptoKeyRing, verifyTime: Int64) throws -> Bool {
        try verifyDetached(signature: signature, input: .left(plainText), keyRing: keyRing, verifyTime: verifyTime)
    }

    public static func verifyDetached(signature: String, plainData: Data, keyRing: CryptoKeyRing, verifyTime: Int64) throws -> Bool {
        try verifyDetached(signature: signature, input: .right(plainData), keyRing: keyRing, verifyTime: verifyTime)
    }

    private static func verifyDetached(signature: String, input: Either<String, Data>, keyRing: CryptoKeyRing, verifyTime: Int64) throws -> Bool {
        var error: NSError?

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText.trimTrailingSpaces())
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }

        let signature = CryptoGo.CryptoNewPGPSignatureFromArmored(signature, &error)
        if let err = error {
            throw err
        }

        do {
            try keyRing.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
            return true
        } catch {
            return false
        }
    }

    public static func getPrivateKeyPassphrase(password: String, salt: String, error: inout NSError?) -> String {
        let passwordSlic = password.data(using: .utf8)
        let userPrivPassSlic = CryptoGo.SrpMailboxPassword(passwordSlic,
                                                           Data(base64Encoded: salt,
                                                                options: .init(rawValue: 0)),
                                                           &error)

        let userPrivateKeyPassphrase = String(data: userPrivPassSlic!, encoding: .utf8)!
        if error != nil {
            return ""
        }

        // 傑出的一手, thanks Steven
        let index = userPrivateKeyPassphrase.index(userPrivateKeyPassphrase.startIndex,
                                                   offsetBy: 29)
        return String(userPrivateKeyPassphrase[index...])
    }

    public static func get(keyPacket: String, keyRings: [CryptoKeyRing]) throws -> CryptoSessionKey? {
        var ret: CryptoSessionKey?

        for keyRing in keyRings {
            do {
                ret = try keyRing.decryptSessionKey(Data(base64Encoded: keyPacket,
                                                         options: .init(rawValue: 0)))
                break
            } catch {
                // TODO:: catch error and find a way to log it
                // } catch let error as NSError {
                // let msg = "Error: \(error), \(error.userInfo)"
                // DDLogDebug(msg)
                // SentrySDK.capture(error: error)
            }
        }

        return ret
    }
}
