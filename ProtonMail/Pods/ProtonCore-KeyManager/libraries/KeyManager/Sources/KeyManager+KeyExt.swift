//
//  Key+Ext.swift
//  ProtonCore-KeyManager - Created on 4/19/21.
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
import ProtonCoreCrypto
import ProtonCoreDataModel

/// Array<Key> extensions
extension Array where Element: Key {

    /// loop and combin all keys in binary
    public var binPrivKeys: Data {
        var out = Data()
        var error: NSError?
        for key in self {
            if let privK = CryptoGo.ArmorUnarmor(key.privateKey, &error) {
                out.append(privK)
            }
        }
        return out
    }

    public var binPrivKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in self {
            if let privK = CryptoGo.ArmorUnarmor(key.privateKey, &error) {
                out.append(privK)
            }
        }
        return out
    }
}

/// Array<Key> extensions
extension Array where Element == Data {
    public var toArmored: [ArmoredKey] {
        var out = [ArmoredKey]()
        var error: NSError?
        for key in self {
            let privK = CryptoGo.ArmorArmorKey(key, &error)
            out.append(ArmoredKey.init(value: privK))
        }
        return out
    }
}

extension Key {

    /// TODO:: need to handle the nil case
    internal var binPrivKeys: Data {
        var error: NSError?
        return CryptoGo.ArmorUnarmor(self.privateKey, &error)!
    }

    public var publicKey: String {
        return self.privateKey.publicKey
    }

    public var fingerprint: String {
        return self.privateKey.fingerprint
    }

    public var shortFingerprint: String {
        let fignerprint = self.fingerprint
        if fignerprint.count > 8 {
            return String(fignerprint.prefix(8))
        }
        return fignerprint
    }

    public enum Errors: Error {
        case tokenDecryptionFailed
        case tokenSignatureVerificationFailed
        case buildKeyRingFailed
    }

    // Mark - Key v2
    /// Key_1_2  the func to get the real passphrase that can decrypt the body. TODO:: add unit tests
    /// - Parameters:
    ///   - userBinKeys: user keys need to unarmed to binary
    ///   - mailboxPassphrase: user password hashed with the key salt
    /// - Throws: crypt exceptions
    /// - Returns: passphrase
    @available(*, deprecated, message: "Please use ProtonCore-Crypto, you can find the same function")
    public func passphrase(userBinKeys: [Data], mailboxPassphrase: String) throws -> String {
        guard let token = self.token, let signature = self.signature else {
            return mailboxPassphrase
        }

        let plainToken: String
        do {
            plainToken = try token.decryptMessageNonOptional(binKeys: userBinKeys, passphrase: mailboxPassphrase)
        } catch {
            throw Errors.tokenDecryptionFailed
        }

        guard let verificationKeyRing = try Decryptor.buildPublicKeyRing(binKeys: userBinKeys) else {
            throw Errors.buildKeyRingFailed
        }

        let verification = try Decryptor.verifyDetached(signature: signature,
                                                       plainText: plainToken,
                                                       keyRing: verificationKeyRing,
                                                       verifyTime: 0) // Temporary, to support devices with wrong local time
        if verification != true {
            throw Errors.tokenSignatureVerificationFailed
        }
        return plainToken
    }

    public func passphrase(userKeys: [Key], mailboxPassphrase: String) throws -> String {
        return try self.passphrase(userPrivateKeys: userKeys.toArmoredPrivateKeys,
                                   mailboxPassphrase: Passphrase.init(value: mailboxPassphrase)).value
    }

    public func decryptMessageNonOptional(encrypted: String, userBinKeys privateKeys: [Data], passphrase: String) throws -> String {
        let addressKeyPassphrase = try self.passphrase(userPrivateKeys: privateKeys.toArmored,
                                                       mailboxPassphrase: Passphrase.init(value: passphrase))

        return try encrypted.decryptMessageWithSingleKeyNonOptional(ArmoredKey.init(value: self.privateKey),
                                                                    passphrase: Passphrase.init(value: addressKeyPassphrase.value))
    }
}
