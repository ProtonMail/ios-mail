//
//  Crypto+String.swift
//  ProtonCore-Crypto - Created on 9/11/19.
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
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

extension String {
    
    /// get the public key from the armored private key.
    public var publicKey: String {
        do {
            let key = try throwing { error in CryptoNewKeyFromArmored(self, &error) }
            return key?.getArmoredPublicKey(nil) ?? ""
        } catch {
            return ""
        }
    }
    
    /// get the fingerprint value from armored pub/priv key
    public var fingerprint: String {
        do {
            let key = try throwing { error in CryptoNewKeyFromArmored(self, &error) }
            return key?.getFingerprint() ?? ""
        } catch {
            return ""
        }
    }
    
    // get sha256 fingerprint
    public var sha256Fingerprint: [String] {
        do {
            let jsonFingerprints = try throwing { error in HelperGetJsonSHA256Fingerprints(self, &error) }
            guard let jsondata = jsonFingerprints else {
                return []
            }
            let decoder = JSONDecoder()
            let object = try decoder.decode([String].self, from: jsondata)
            return object
        } catch {
            return []
        }
    }
    
    //
    public var unArmor: Data? {
        return ArmorUnarmor(self, nil)
    }
    
    public func getSignature() throws -> String? {
        let clearTextMessage = try throwing { error in CryptoNewClearTextMessageFromArmored(self, &error) }
        let dec_out_att: String? = clearTextMessage?.getString()
        return dec_out_att
    }
    
    public func split() throws -> SplitMessage? {
        let out = try throwing { error in CryptoNewPGPSplitMessageFromArmored(self, &error) }
        return out
    }
    
    // self is private key
    public func check(passphrase: String) -> Bool {
        do {
            let key = try throwing { error in CryptoNewKeyFromArmored(self, &error) }
            let passSlice = passphrase.data(using: .utf8)
            let unlockedKey = try key?.unlock(passSlice)
            var result: ObjCBool = true
            try unlockedKey?.isLocked(&result)
            let isUnlock = !result.boolValue
            return isUnlock
        } catch {
            return false
        }
    }
    
    public func check(passphrase: Passphrase) -> Bool {
        return self.check(passphrase: passphrase.value)
    }
}

extension String {
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptMessage(binKeys: [Data], passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: binKeys, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please use ArmoredKey. we shoudle try to avoid using unarmored keys(binkeys)")
    public func decryptMessageNonOptional(binKeys: [Data], passphrase: String) throws -> String {
        return try Crypto().decrypt(encrypted: self, privateKeys: binKeys, passphrase: passphrase)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encrypt(withPrivKey key: String, mailbox_pwd: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, privateKey: key, passphrase: mailbox_pwd)
    }
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encrypt(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: publicKey, privateKey: privateKey, passphrase: passphrase)
    }
    
    public func decryptMessageWithSingleKeyNonOptional(_ privateKey: ArmoredKey, passphrase: Passphrase) throws -> String {
        let decryptionKey = DecryptionKey.init(privateKey: privateKey,
                                               passphrase: passphrase)
        return try Decryptor.decrypt(decryptionKeys: [decryptionKey], encrypted: ArmoredMessage.init(value: self))
    }
    
    public func encryptNonOptional(withPrivKey key: String, mailbox_pwd: String) throws -> String {
        let publicKey = key.publicKey
        return try self.encryptNonOptional(withPubKey: publicKey, privateKey: key, passphrase: mailbox_pwd)
    }
    
    /// encrypt message with public key only. no sign
    /// - Parameter publicKey: armored public key for encryption
    /// - Returns: encrypted message
    public func encryptNonOptional(publicKey: String) throws -> String {
        let encrypted: ArmoredMessage = try Encryptor.encrypt(publicKey: ArmoredKey.init(value: publicKey),
                                                              cleartext: self)
        return encrypted.value
    }
    
    /// encrypt message with public key. signer - privkey & passphrase
    /// - Parameters:
    ///   - publicKey: armored public for encryption
    ///   - privateKey: armored private key for signing
    ///   - passphrase: private key passphrase
    /// - Throws: exception
    /// - Returns: encrypted message - Armored string
    public func encryptNonOptional(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String {
        let signer = SigningKey.init(privateKey: ArmoredKey.init(value: privateKey),
                                     passphrase: Passphrase.init(value: passphrase))
        
        let encrypted: ArmoredMessage = try Encryptor.encrypt(publicKey: ArmoredKey.init(value: publicKey),
                                                              cleartext: self, signerKey: signer)
        return encrypted.value
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, token: passphrase)
    }
    
    /// decrypt armored encrypted message
    /// - Parameter passphrase: passphrase
    /// - Throws: exception
    /// - Returns: clear text
    public func encryptNonOptional(password passphrase: String) throws -> String {
        return try Encryptor.encrypt(clearText: self, token: TokenPassword.init(value: passphrase)).value
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrypted: self, token: passphrase)
    }
    
    /// encrypt clear text with your own passphrase
    /// - Parameter passphrase: passphrase
    /// - Throws: exception
    /// - Returns: encrypted message - Armored string
    func decryptNonOptional(password passphrase: String) throws -> String {
        return try Decryptor.decrypt(encrypted: ArmoredMessage.init(value: self), token: TokenPassword.init(value: passphrase))
    }
}
