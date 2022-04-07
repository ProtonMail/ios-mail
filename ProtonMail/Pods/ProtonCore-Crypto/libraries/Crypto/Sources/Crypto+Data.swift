//
//  Crypto+Data.swift
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
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

extension Data { // need follow the gomobile fixes
    /// This computed value is only needed because of [this](https://github.com/golang/go/issues/33745) issue in the
    /// golang/go repository. It is a workaround until the problem is solved upstream.
    ///
    /// The data object is converted into an array of bytes and than returned wrapped in an `NSMutableData` object. In
    /// thas way Gomobile takes it as it is without copying. The Swift side remains responsible for garbage collection.
    public var mutable: NSMutableData {
        var array = [UInt8](self)
        return NSMutableData(bytes: &array, length: count)
    }
}

extension Data {
    
    public func getKeyPackage(publicKey: String, algo: String) throws -> Data? {
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let key = try throwing { error in CryptoNewKeyFromArmored(publicKey, &error) }
        let keyRing = try throwing { error in CryptoNewKeyRing(key, &error) }
        
        return try keyRing?.encryptSessionKey(symKey)
    }
    
    public func getKeyPackage(publicKey binKey: Data, algo: String) throws -> Data? {
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let key = try throwing { error in CryptoNewKey(binKey, &error) }
        let keyRing = try throwing { error in CryptoNewKeyRing(key, &error) }
        
        return try keyRing?.encryptSessionKey(symKey)
    }
    
    public func getSymmetricPacket(withPwd pwd: String, algo: String) throws -> Data? {
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let passSlic = pwd.data(using: .utf8)
        let packet = try throwing { error in CryptoEncryptSessionKeyWithPassword(symKey, passSlic, &error) }
        return packet
    }
    
    // self is public key
    public func isPublicKeyExpired() -> Bool? {
        do {
            let key = try throwing { error in CryptoNewKey(self, &error) }
            return key?.isExpired()
        } catch {
            return false
        }
    }
}

extension Data {
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }
    
    public func decryptAttachmentNonOptional(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data {
        return try Crypto().decryptAttachmentNonOptional(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }

    func decryptAttachmentWithSingleKeyNonOptional(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data {
        return try Crypto().decryptAttachmentNonOptional(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try Crypto.signDetached(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    public func signAttachmentNonOptional(byPrivKey: String, passphrase: String) throws -> String {
        return try Crypto.signDetachedNonOptional(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encryptAttachment(fileName: String, pubKey: String) throws -> SplitMessage? {
        return try Crypto().encryptAttachment(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    public func encryptAttachmentNonOptional(fileName: String, pubKey: String) throws -> SplitMessage {
        return try Crypto().encryptAttachmentNonOptional(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    // could remove and dirrectly use Crypto()
    static func makeEncryptAttachmentProcessor(fileName: String, totalSize: Int, pubKey: String) throws -> AttachmentProcessor {
        return try Crypto().encryptAttachmentLowMemory(fileName: fileName, totalSize: totalSize, publicKey: pubKey)
    }
    
}
