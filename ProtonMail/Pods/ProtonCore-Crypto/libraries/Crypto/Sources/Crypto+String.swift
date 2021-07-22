//
//  Crypto+String.swift
//  ProtonCore-Crypto - Created on 9/11/19.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import Crypto

extension String {
    
    /// get the public key from the armored private key.
    public var publicKey: String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        return key?.getArmoredPublicKey(nil) ?? ""
    }
    
    /// get the fingerprint value from armored pub/priv key
    public var fingerprint: String {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return ""
        }
        return key?.getFingerprint() ?? ""
    }
    
    //
    public var unArmor: Data? {
        return ArmorUnarmor(self, nil)
    }
    
    public func getSignature() throws -> String? {
        var error: NSError?
        let clearTextMessage = CryptoNewClearTextMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        let dec_out_att: String? = clearTextMessage?.getString()
        return dec_out_att
    }
    
    public func split() throws -> SplitMessage? {
        var error: NSError?
        let out = CryptoNewPGPSplitMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        return out
    }
    
    // self is private key
    public func check(passphrase: String) -> Bool {
        var error: NSError?
        let key = CryptoNewKeyFromArmored(self, &error)
        if error != nil {
            return false
        }
        
        let passSlic = passphrase.data(using: .utf8)
        do {
            let unlockedKey = try key?.unlock(passSlic)
            var result: ObjCBool = true
            try unlockedKey?.isLocked(&result)
            let isUnlock = !result.boolValue
            return isUnlock
        } catch {
            return false
        }
    }
}

extension String {

    public func decryptMessage(binKeys: [Data], passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: binKeys, passphrase: passphrase)
    }
    
    public func decryptMessageWithSinglKey(_ privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrytped: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    public func encrypt(withPrivKey key: String, mailbox_pwd: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, privateKey: key, passphrase: mailbox_pwd)
    }
    
    /// encrypt message with public key. singer - privkey & passphrase
    /// - Parameters:
    ///   - publicKey: armored public for encryption
    ///   - privateKey: armored private key for signing
    ///   - passphrase: private key passphrase
    /// - Throws: exception
    /// - Returns: encrypted message - Armored string
    public func encrypt(withPubKey publicKey: String, privateKey: String, passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, publicKey: publicKey, privateKey: privateKey, passphrase: passphrase)
    }
    
    /// decrypt armored encrypted message
    /// - Parameter passphrase: passphrase
    /// - Throws: exception
    /// - Returns: clear text
    public func encrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().encrypt(plainText: self, token: passphrase)
    }
    
    /// encrypt clear text with your own passphrase
    /// - Parameter passphrase: passphrase
    /// - Throws: exception
    /// - Returns: encrypted message - Armored string
    func decrypt(withPwd passphrase: String) throws -> String? {
        return try Crypto().decrypt(encrypted: self, token: passphrase)
    }
}
