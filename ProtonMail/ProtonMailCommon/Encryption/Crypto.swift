//
//  Crypto.swift
//  ProtonMail - Created on 9/11/19.
//
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
    

import Foundation
import Crypto

typealias KeyRing             = CryptoKeyRing
typealias SplitMessage        = CryptoPGPSplitMessage
typealias PlainMessage        = CryptoPlainMessage
typealias PGPMessage          = CryptoPGPMessage
typealias PGPSignature        = CryptoPGPSignature
typealias AttachmentProcessor = CryptoAttachmentProcessor
typealias SymmetricKey        = CryptoSymmetricKey

typealias ExplicitVerifyMessage = HelperExplicitVerifyMessage
typealias SignatureVerification = CryptoSignatureVerificationError


extension Data { ///need follow the gomobile fixes
    /// This computed value is only needed because of [this](https://github.com/golang/go/issues/33745) issue in the
    /// golang/go repository. It is a workaround until the problem is solved upstream.
    ///
    /// The data object is converted into an array of bytes and than returned wrapped in an `NSMutableData` object. In
    /// thas way Gomobile takes it as it is without copying. The Swift side remains responsible for garbage collection.
    var mutable: NSMutableData {
        var array = [UInt8](self)
        return NSMutableData(bytes: &array, length: count)
    }
}

//Helper
class Crypto {

    private enum Algo : String {
        case ThreeDES  = "3des"
        case TripleDES = "tripledes" // Both "3des" and "tripledes" refer to 3DES.
        case CAST5     = "cast5"
        case AES128    = "aes128"
        case AES192    = "aes192"
        case AES256    = "aes256"
        
        var value : String {
            return self.rawValue
        }
    }
//    enum SignatureStatus {
//        SIGNATURE_OK          int = 0
//        SIGNATURE_NOT_SIGNED  int = 1
//        SIGNATURE_NO_VERIFIER int = 2
//        SIGNATURE_FAILED      int = 3
//    }
    
    /// Mark -- Message
    
    // no verify
    public func decrypt(encrytped message: String, privateKey: String, passphrase: String) throws -> String {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let plainMessage = try keyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0)
        return plainMessage.getString()
    }
    
    public func decrypt(encrytped message: String, privateKey binKeys: Data, passphrase: String) throws -> String {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let plainMessage = try keyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0)
        return plainMessage.getString()
    }
    
    public func decrypt(encrytped binMessage: Data, privateKey: String, passphrase: String) throws -> String {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        let pgpMsg = CryptoNewPGPMessage(binMessage.mutable as Data)
        let plainMessage = try keyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0)
        return plainMessage.getString()
    }
    
    public func decrypt(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey binKeys: Data,
                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRing(verifierBinKey.mutable as Data)
        let plainMessage = try keyRing.decrypt(pgpMsg, verifyKey: verifier, verifyTime: verifyTime)
        return plainMessage
    }
    
    
    public func decrypt(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey armorKey: String,
                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(armorKey)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRing(verifierBinKey.mutable as Data)
        let plainMessage = try keyRing.decrypt(pgpMsg, verifyKey: verifier, verifyTime: verifyTime)
        return plainMessage
    }
    
    public func decryptVerify(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey armorKey: String,
                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(armorKey)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRing(verifierBinKey.mutable as Data)
        let verified = HelperDecryptExplicitVerify(pgpMsg, keyRing, verifier, verifyTime, &error)
        if let err = error {
            throw err
        }
        return verified
    }
    
    public func decryptVerify(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey binKeys: Data,
                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRing(verifierBinKey.mutable as Data)
        let verified = HelperDecryptExplicitVerify(pgpMsg, keyRing, verifier, verifyTime, &error)
        if let err = error {
            throw err
        }
        return verified
    }
    
    
    public func decryptVerify(encrytped message: String,
                        publicKey: String,
                        privateKey armorKey: String,
                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(armorKey)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRingArmored(publicKey)
        let verified = HelperDecryptExplicitVerify(pgpMsg, keyRing, verifier, verifyTime, &error)
        if let err = error {
            throw err
        }
        return verified
    }
    
    public func decryptVerify(encrytped message: String,
                        publicKey: String,
                        privateKey binKeys: Data,
                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }
        let verifier = try pgp.buildKeyRingArmored(publicKey)
        let verified = HelperDecryptExplicitVerify(pgpMsg, keyRing, verifier, verifyTime, &error)
        if let err = error {
            throw err
        }
        return verified
    }
    
    
    public func encrypt(plainText: String, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String? {
        let pgp = CryptoGetGopenPGP()!
        let publicKeyRing = try pgp.buildKeyRingArmored(publicKey)
        let plainTextMessage = CryptoNewPlainMessageFromString(plainText)
        var signerKeyRing : KeyRing?
        if !signerPrivateKey.isEmpty {
            signerKeyRing = try pgp.buildKeyRingArmored(signerPrivateKey)
            try signerKeyRing?.unlock(withPassphrase: passphrase)
        }
        let cryptedMessage : PGPMessage = try publicKeyRing.encrypt(plainTextMessage, privateKey: signerKeyRing)
        var error: NSError?
        let armoredMessage = cryptedMessage.getArmored(&error)
        
        if let err = error {
            throw err
        }
        return armoredMessage
    }
    
    public func encrypt(plainText: String, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
        let pgp = CryptoGetGopenPGP()!
        let publicKeyRing = try pgp.buildKeyRing(binKey.mutable as Data)
        let plainTextMessage = CryptoNewPlainMessageFromString(plainText)
        let signerKeyRain = try pgp.buildKeyRingArmored(signerPrivateKey)
        
        try signerKeyRain.unlock(withPassphrase: passphrase)
        let cryptedMessage : PGPMessage = try publicKeyRing.encrypt(plainTextMessage, privateKey: signerKeyRain)
        var error: NSError?
        let armoredMessage = cryptedMessage.getArmored(&error)
        
        if let err = error {
            throw err
        }
        return armoredMessage
    }
    
    public func encrypt(plainText: String, publicKey binKey: Data) throws -> String? {
        let pgp = CryptoGetGopenPGP()!
        let publicKeyRing = try pgp.buildKeyRing(binKey.mutable as Data)
        let plainTextMessage = CryptoNewPlainMessageFromString(plainText)
        let cryptedMessage : PGPMessage = try publicKeyRing.encrypt(plainTextMessage, privateKey: nil)
        var error: NSError?
        let armoredMessage = cryptedMessage.getArmored(&error)
        
        if let err = error {
            throw err
        }
        return armoredMessage
    }
    
    /// Mark -- encrypt with password
    public func encrypt(plainText: String, token: String) throws -> String? {
        let plainTextMessage = CryptoNewPlainMessageFromString(plainText)
        let key = CryptoNewSymmetricKeyFromToken(token, Algo.AES256.value)
        let pgpMessage = try key?.encrypt(plainTextMessage)
        var error: NSError?
        let armoredMessage = pgpMessage?.getArmored(&error)
        if let err = error {
            throw err
        }
        return armoredMessage
    }
    
    public func decrypt(encrypted: String, token: String) throws -> String? {
        let key = CryptoNewSymmetricKeyFromToken(token, "")
        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(encrypted, &error)
        if let err = error {
            throw err
        }
        let message = try key?.decrypt(pgpMsg)
        return message?.getString()
    }

    ///Mark -- Attachment
    
     // no verify
    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey: String, passphrase: String) throws -> Data? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
        let plainMessage = try keyRing.decryptAttachment(splitMessage)
        return plainMessage.getBinary()
    }
    
    public func decryptAttachment1(splitMessage: SplitMessage, privateKey: String, passphrase: String) throws -> Data? {
       let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        let plainMessage = try keyRing.decryptAttachment(splitMessage)
        return plainMessage.getBinary()
    }
    
    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey binKeys: Data, passphrase: String) throws -> Data? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
        let plainMessage = try keyRing.decryptAttachment(splitMessage)
        return plainMessage.getBinary()
    }
    
    public func decryptAttachment(encrypted: String, privateKey: String, passphrase: String) throws -> Data? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        var error: NSError?
        let splitMessage = CryptoNewPGPSplitMessageFromArmored(encrypted, &error)
        if let err = error {
            throw err
        }
        let plainMessage = try keyRing.decryptAttachment(splitMessage)
        return plainMessage.getBinary()
    }

    public func encryptAttachment(plainData: Data, fileName: String, publicKey: String) throws -> SplitMessage? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(publicKey)
        var error: NSError?
        let splitMessage = HelperEncryptAttachment(plainData, fileName, keyRing, &error)//without mutable
        if let err = error {
            throw err
        }
        return splitMessage
    }

    public func encryptAttachmentLowMemory(fileName:String, totalSize: Int, publicKey: String) throws -> AttachmentProcessor {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(publicKey)
        let processor = try keyRing.newLowMemoryAttachmentProcessor(totalSize, fileName: fileName)
        return processor
    }

    
    /// Mark -- sign
    
    public func signDetached(plainData: Data, privateKey: String, passphrase: String) throws -> String? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        let plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
        let pgpSignature = try keyRing.signDetached(plainMessage)
        var error: NSError?
        let signaure = pgpSignature.getArmored(&error)
        if let err = error {
            throw err
        }
        return signaure
    }
    
    public func signDetached(plainData: String, privateKey: String, passphrase: String) throws -> String {
         let pgp = CryptoGetGopenPGP()!
         let keyRing = try pgp.buildKeyRingArmored(privateKey)
         try keyRing.unlock(withPassphrase: passphrase)
         let plainMessage = CryptoNewPlainMessageFromString(plainData)
         let pgpSignature = try keyRing.signDetached(plainMessage)
         var error: NSError?
         let signaure = pgpSignature.getArmored(&error)
         if let err = error {
             throw err
         }
         return signaure
     }
    
    public func verifyDetached(signature: String, plainData: Data, publicKey: String, verifyTime: Int64) throws -> Bool {
        let pgp = CryptoGetGopenPGP()!
        let pubKeyRing = try pgp.buildKeyRingArmored(publicKey)
        let plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
        var error: NSError?
        let signature = CryptoNewPGPSignatureFromArmored(signature, &error)
        if let err = error {
            throw err
        }
        do {
            try pubKeyRing.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
            return true
        } catch {
            return false
        }
//        let verified = MobileVerifyDetached(pubKeyRing, plainMessage, signature, verifyTime, &error)
//        if let err = error {
//            throw err
//        }
//        guard let v = verified, v.status == 0 else {
//            return false
//        }
    }
    
    public func verifyDetached(signature: String, plainText: String, publicKey: String, verifyTime: Int64) throws -> Bool {
        let pgp = CryptoGetGopenPGP()!
        let pubKeyRing = try pgp.buildKeyRingArmored(publicKey)
        let plainMessage = CryptoNewPlainMessageFromString(plainText)
        var error: NSError?
        let signature = CryptoNewPGPSignatureFromArmored(signature, &error)
        if let err = error {
            throw err
        }
        do {
            try pubKeyRing.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
            return true
        } catch {
            return false
        }
        
        
        //        let verified = MobileVerifyDetached(pubKeyRing, plainMessage, signature, verifyTime, &error)
        //        if let err = error {
        //            throw err
        //        }
        //        guard let v = verified, v.status == 0 else {
        //            return false
        //        }
    }
    
//    let _ = try sharedOpenPGP.verifyTextSignDetached(c.sign,
//                                                                                    plainText: c.data,
//                                                                                    publicKey: key.publicKey,
//                                                                                    verifyTime: 0, ret0_: &ok)
//    (pm *PmCrypto) VerifyTextSignDetachedBinKey(signature string, plaintext string, publicKey *KeyRing, verifyTime int64) (bool, error):
//    (pm *PmCrypto) VerifyBinSignDetachedBinKey(signature string, plainData []byte, publicKey *KeyRing, verifyTime int64) (bool, error):
//    * (to verify) (keyRing *KeyRing) VerifyDetached(message *PlainMessage, signature *PGPSignature, verifyTime int64) (error)
//
//
    /// Mark -- session
    
    //key packet part
    public func getSession(keyPacket: Data, privateKeys binKeys: Data, passphrase: String) throws -> SymmetricKey? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRing(binKeys.mutable as Data)
        try keyRing.unlock(withPassphrase: passphrase)
        let key = try keyRing.decryptSessionKey(keyPacket.mutable as Data)
        return key
    }
    
    public func getSession(keyPacket: Data, privateKey: String, passphrase: String) throws -> SymmetricKey? {
        let pgp = CryptoGetGopenPGP()!
        let keyRing = try pgp.buildKeyRingArmored(privateKey)
        try keyRing.unlock(withPassphrase: passphrase)
        let key = try keyRing.decryptSessionKey(keyPacket.mutable as Data)
        return key
    }
    
    
    
    /// Mark -- static
    
    static func updateTime( _ time : Int64) {
        let pgp = CryptoGetGopenPGP()!
        pgp.updateTime(time)
    }
    
    static func updatePassphrase(privateKey: String, oldPassphrase: String, newPassphrase: String) throws -> String {
        let pgp = CryptoGetGopenPGP()!
        var error: NSError?
        let newKey = pgp.updatePrivateKeyPassphrase(privateKey, oldPassphrase: oldPassphrase, newPassphrase: newPassphrase, error: &error)
        if let err = error {
            throw err
        }
        return newKey
    }
    
    static func random(byte: Int) throws -> Data {
        let pgp = CryptoGetGopenPGP()!
        return try pgp.randomTokenSize(byte)
    }

}


extension String {
    //TODO:: add test
    var publicKey : String  {
        let crypto = CryptoGetGopenPGP()!
        do {
            let keyring = try crypto.buildKeyRingArmored(self)
             return keyring.getArmoredPublicKey(nil)
        } catch {
            return ""
        }
    }
    
    var fingerprint : String {
        let crypto = CryptoGetGopenPGP()!
        do {
            let keyring = try crypto.buildKeyRingArmored(self)
            return keyring.getFingerprint(nil)
        } catch {
            return ""
        }
    }
    
    var unArmor : Data? {
        return ArmorUnarmor(self, nil)
    }
    
    func getSignature() throws -> String? {
        var error : NSError?
        let clearTextMessage = CryptoNewClearTextMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        let dec_out_att : String? = clearTextMessage?.getString()
       
        return dec_out_att
    }
    
    
    func split() throws -> SplitMessage? {
        var error : NSError?
        let out = CryptoNewPGPSplitMessageFromArmored(self, &error)
        if let err = error {
            throw err
        }
        return out
    }
    
    
    //self is private key
    func check(passphrase: String) -> Bool {
        let crypto = CryptoGetGopenPGP()!
        do {
            let keyring = try crypto.buildKeyRingArmored(self)
            return keyring.checkPassphrase(passphrase)
        } catch {
            return false
        }
    }
}


extension Data {
    
    func getKeyPackage(publicKey: String,  algo : String) throws -> Data? {
        let crypto = CryptoGetGopenPGP()!
        let symKey = CryptoCreateSymmetricKey(self.mutable as Data, algo)
        let keyRing = try crypto.buildKeyRingArmored(publicKey)
        return try keyRing.encryptSessionKey(symKey)
    }
    
    func getKeyPackage(publicKey binKey: Data, algo : String) throws -> Data? {
        let crypto = CryptoGetGopenPGP()!
        let symKey = CryptoCreateSymmetricKey(self.mutable as Data, algo)
        let keyRing = try crypto.buildKeyRing(binKey.mutable as Data)
        return try keyRing.encryptSessionKey(symKey)
    }
    
    func getSymmetricPacket(withPwd pwd: String, algo : String) throws -> Data? {
        let symKey = CryptoCreateSymmetricKey(self.mutable as Data, algo)
        return try symKey?.encrypt(toKeyPacket: pwd)
    }
    
    //self is public key
    func isPublicKeyExpired() -> Bool? {
        var result: ObjCBool = false
        try? CryptoGetGopenPGP()!.isKeyExpired(self, ret0_: &result)
        return result.boolValue
    }
}
