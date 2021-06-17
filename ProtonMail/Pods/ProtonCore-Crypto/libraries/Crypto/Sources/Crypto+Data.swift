//
//  Crypto+Data.swift
//  ProtonCore-Crypto - Created on 9/11/19.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import Crypto

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
        var error: NSError?
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let key = CryptoNewKeyFromArmored(publicKey, &error)
        if let err = error {
            throw err
        }
        
        let keyRing = CryptoNewKeyRing(key, &error)
        if let err = error {
            throw err
        }
        
        return try keyRing?.encryptSessionKey(symKey)
    }
    
    public func getKeyPackage(publicKey binKey: Data, algo: String) throws -> Data? {
        var error: NSError?
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let key = CryptoNewKey(binKey, &error)
        if let err = error {
            throw err
        }
        
        let keyRing = CryptoNewKeyRing(key, &error)
        if let err = error {
            throw err
        }
        
        return try keyRing?.encryptSessionKey(symKey)
    }
    
    public func getSymmetricPacket(withPwd pwd: String, algo: String) throws -> Data? {
        var error: NSError?
        // TODO: Needs double check
        let symKey = CryptoNewSessionKeyFromToken(self.mutable as Data, algo)
        let passSlic = pwd.data(using: .utf8)
        let packet = CryptoEncryptSessionKeyWithPassword(symKey, passSlic, &error)
        if let err = error {
            throw err
        }
        return packet
    }
    
    // self is public key
    public func isPublicKeyExpired() -> Bool? {
        var error: NSError?
        let key = CryptoNewKey(self, &error)
        if error != nil {
            return false
        }
        return key?.isExpired()
    }
}

extension Data {
    
    public func decryptAttachment(_ keyPackage: Data, passphrase: String, privKeys: [Data]) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privKeys, passphrase: passphrase)
    }

    func decryptAttachmentWithSingleKey(_ keyPackage: Data, passphrase: String, privateKey: String) throws -> Data? {
        return try Crypto().decryptAttachment(keyPacket: keyPackage, dataPacket: self, privateKey: privateKey, passphrase: passphrase)
    }
    
    public func signAttachment(byPrivKey: String, passphrase: String) throws -> String? {
        return try Crypto.signDetached(plainData: self, privateKey: byPrivKey, passphrase: passphrase)
    }
    
    public func encryptAttachment(fileName: String, pubKey: String) throws -> SplitMessage? {
        return try Crypto().encryptAttachment(plainData: self, fileName: fileName, publicKey: pubKey)
    }
    
    // could remove and dirrectly use Crypto()
    static func makeEncryptAttachmentProcessor(fileName: String, totalSize: Int, pubKey: String) throws -> AttachmentProcessor {
        return try Crypto().encryptAttachmentLowMemory(fileName: fileName, totalSize: totalSize, publicKey: pubKey)
    }
    
//    //key packet part
//    public func getSessionFromPubKeyPackage(_ passphrase: String, privKeys: [Data]) throws -> SymmetricKey? {
//        return try Crypto().getSession(keyPacket: self, privateKeys: privKeys, passphrase: passphrase)
//    }
//    
//    //key packet part
//    public func getSessionFromPubKeyPackage(addrPrivKey: String, passphrase: String) throws -> SymmetricKey? {
//        return try Crypto().getSession(keyPacket: self, privateKey: addrPrivKey, passphrase: passphrase)
//    }
    
}
