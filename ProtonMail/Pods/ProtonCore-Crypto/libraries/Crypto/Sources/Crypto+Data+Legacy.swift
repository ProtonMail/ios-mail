//
//  Crypto+Data+Legacys.swift
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
        let passSlice = pwd.data(using: .utf8)
        let packet = try throwing { error in CryptoEncryptSessionKeyWithPassword(symKey, passSlice, &error) }
        return packet
    }
}

extension Data {
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }
    @available(*, deprecated, message: "Please use arormed keys. avoid binary keys. check `Decryptor.decrypt(decryptionKeys:)`")
    public func decryptAttachmentNonOptional(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data {
        return try Crypto().decryptAttachmentNonOptional(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }
    @available(*, deprecated, message: "Please use the non-optional variant")
    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    func decryptAttachmentWithSingleKeyNonOptional(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data {
        let split = SplitPacket.init(dataPacket: self, keyPacket: keyPackage)
        let decryptionKey = DecryptionKey.init(privateKey: ArmoredKey.init(value: privateKey),
                                               passphrase: Passphrase.init(value: passphrase))
        return try Decryptor.decrypt(decryptionKeys: [decryptionKey], split: split)
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try Crypto.signDetached(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    public func signAttachmentNonOptional(byPrivKey: String, passphrase: String) throws -> String {
        let signer = SigningKey.init(privateKey: ArmoredKey.init(value: byPrivKey),
                                     passphrase: Passphrase.init(value: passphrase))
        return try Sign.signDetached(signingKey: signer, plainData: self).value
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encryptAttachment(fileName: String, pubKey: String) throws -> SplitMessage? {
        return try Crypto().encryptAttachment(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    public func encryptAttachmentNonOptional(fileName: String, pubKey: String) throws -> SplitMessage {
        return try Crypto().encryptAttachmentNonOptional(plainData: self, fileName: fileName, publicKey: ArmoredKey.init(value: pubKey))
    }
    
    // could remove and dirrectly use Crypto()
    static func makeEncryptAttachmentProcessor(fileName: String, totalSize: Int, pubKey: String) throws -> AttachmentProcessor {
        return try Crypto().encryptAttachmentLowMemory(fileName: fileName, totalSize: totalSize, publicKey: ArmoredKey.init(value: pubKey))
    }
    
}
