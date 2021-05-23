//
//  Crypto+Extension.swift
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

typealias KeyRing             = CryptoKeyRing
typealias SplitMessage        = CryptoPGPSplitMessage
typealias PlainMessage        = CryptoPlainMessage
typealias PGPMessage          = CryptoPGPMessage
typealias PGPSignature        = CryptoPGPSignature
typealias AttachmentProcessor = CryptoAttachmentProcessor
typealias SymmetricKey        = CryptoSessionKey

typealias ExplicitVerifyMessage = HelperExplicitVerifyMessage
typealias SignatureVerification = CryptoSignatureVerificationError

// Helper
// class Crypto {
//
//    private enum Algo : String {
//        case ThreeDES  = "3des"
//        case TripleDES = "tripledes" // Both "3des" and "tripledes" refer to 3DES.
//        case CAST5     = "cast5"
//        case AES128    = "aes128"
//        case AES192    = "aes192"
//        case AES256    = "aes256"
//
//        var value : String {
//            return self.rawValue
//        }
//    }
//    enum SignatureStatus {
//        SIGNATURE_OK          int = 0
//        SIGNATURE_NOT_SIGNED  int = 1
//        SIGNATURE_NO_VERIFIER int = 2
//        SIGNATURE_FAILED      int = 3
//    }
//
//    // MARK: - Message
//
//    // no verify
//    public func decrypt(encrytped message: String, privateKey: String, passphrase: String) throws -> String {
//        var error: NSError?
//        let newKey = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return ""
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key.unlock(passSlic)
//
//        let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0).getString() ?? ""
//        return plainMessageString
//    }
//
//    public func decrypt(encrytped message: String, privateKey binKeys: [Data], passphrase: String) throws -> String {
//        for binKey in binKeys {
//            do {
//                var error: NSError?
//                let newKey = CryptoNewKey(binKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                guard let key = newKey else {
//                    continue
//                }
//
//                let passSlic = passphrase.data(using: .utf8)
//                let unlockedKey = try key.unlock(passSlic)
//
//                let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
//                if error != nil {
//                    continue
//                }
//
//                let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0).getString() ?? ""
//                return plainMessageString
//            } catch {
//                continue
//            }
//        }
//        return ""
//    }
//
//    public func decrypt(encrytped binMessage: Data, privateKey: String, passphrase: String) throws -> String {
//        var error: NSError?
//        let newKey = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return ""
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key.unlock(passSlic)
//
//        let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let pgpMsg = CryptoNewPGPMessage(binMessage.mutable as Data)
//
//        let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0).getString() ?? ""
//        return plainMessageString
//    }
//
//    public func decrypt(encrytped message: String,
//                        publicKey verifierBinKey: Data,
//                        privateKey binKeys: [Data],
//                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
//
//        for binKey in binKeys {
//            do {
//                var error: NSError?
//                let newKey = CryptoNewKey(binKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                guard let key = newKey else {
//                    continue
//                }
//
//                let passSlic = passphrase.data(using: .utf8)
//                let unlockedKey = try key.unlock(passSlic)
//
//                let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let verifierKey = CryptoNewKey(verifierBinKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                let verifierKeyRing = CryptoNewKeyRing(verifierKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//                let plainMessage = try privateKeyRing?.decrypt(pgpMsg, verifyKey: verifierKeyRing, verifyTime: verifyTime)
//                return plainMessage
//            } catch {
//                continue
//            }
//        }
//        return nil
//    }
//
//
//    public func decrypt(encrytped message: String,
//                        publicKey verifierBinKey: Data,
//                        privateKey armorKey: String,
//                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
//        var error: NSError?
//        let newKey = CryptoNewKeyFromArmored(armorKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key.unlock(passSlic)
//
//        let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let verifierKey = CryptoNewKey(verifierBinKey.mutable as Data, &error)
//        if let err = error {
//            throw err
//        }
//
//        let verifierKeyRing = CryptoNewKeyRing(verifierKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//        let plainMessage = try privateKeyRing?.decrypt(pgpMsg, verifyKey: verifierKeyRing, verifyTime: verifyTime)
//        return plainMessage
//    }
//
//    public func decryptVerify(encrytped message: String,
//                        publicKey verifierBinKeys: [Data],
//                        privateKey armorKey: String,
//                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
//        var error: NSError?
//
//        let newKey = CryptoNewKeyFromArmored(armorKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key.unlock(passSlic)
//
//        let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let verifierKeyRing = buildKeyRing(keys: verifierBinKeys)
//
//        let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//        let verified = HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error)
//        if let err = error {
//            throw err
//        }
//
//        return verified
//    }
//
//    public func decryptVerify(encrytped message: String,
//                        publicKey verifierBinKeys: [Data],
//                        privateKey binKeys: [Data],
//                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
//
//        var error: NSError?
//
//        let privateKeyRing = buildPrivateKeyRing(keys: binKeys, passphrase: passphrase)
//        let verifierKeyRing = buildKeyRing(keys: verifierBinKeys)
//
//        let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//        let verified = HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error)
//        if let err = error {
//            throw err
//        }
//        return verified
//    }
//
//
//    public func decryptVerify(encrytped message: String,
//                        publicKey: String,
//                        privateKey armorKey: String,
//                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
//        var error: NSError?
//
//        let newKey = CryptoNewKeyFromArmored(armorKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key.unlock(passSlic)
//
//        let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        //FIXME - Needs to double check
//        let verifierKey = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let verifierKeyRing = CryptoNewKeyRing(verifierKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//        let verified = HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error)
//        if let err = error {
//            throw err
//        }
//
//        return verified
//    }
//
//    public func decryptVerify(encrytped message: String,
//                        publicKey: String,
//                        privateKey binKeys: [Data],
//                        passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
//        for binKey in binKeys {
//            do {
//                var error: NSError?
//
//                let newKey = CryptoNewKey(binKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                guard let key = newKey else {
//                    continue
//                }
//
//                let passSlic = passphrase.data(using: .utf8)
//                let unlockedKey = try key.unlock(passSlic)
//
//                let privateKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                //FIXME - Needs to double check
//                let verifierKey = CryptoNewKeyFromArmored(publicKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let verifierKeyRing = CryptoNewKeyRing(verifierKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let pgpMsg = CryptoPGPMessage(fromArmored: message)
//
//                let verified = HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error)
//                if error != nil {
//                    continue
//                }
//
//                return verified
//            } catch {
//                continue
//            }
//        }
//        return nil
//    }
//
//    public func encrypt(plainText: String, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
//        var error: NSError?
//        let privateKey = CryptoNewKeyFromArmored(signerPrivateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try privateKey?.unlock(passSlic)
//
//        let publicKeyData = try unlockedKey?.getPublicKey()
//        let publicKey = CryptoNewKey(publicKeyData, &error)
//        if let err = error {
//            throw err
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainText)
//        let signerKeyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
//        let armoredMessage = cryptedMessage?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return armoredMessage
//    }
//
//    public func encrypt(plainText: String, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String? {
//        var error: NSError?
//        let newKey = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainText)
//
//        var signerKeyRing: KeyRing?
//        if !signerPrivateKey.isEmpty {
//            let signerKey = CryptoNewKeyFromArmored(signerPrivateKey, &error)
//            if let err = error {
//                throw err
//            }
//
//            let passSlic = passphrase.data(using: .utf8)
//            let unlockedSignerKey = try signerKey?.unlock(passSlic)
//
//            signerKeyRing = CryptoNewKeyRing(unlockedSignerKey, &error)
//            if let err = error {
//                throw err
//            }
//        }
//
//        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
//        let armoredMessage = cryptedMessage?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return armoredMessage
//    }
//
//    public func encrypt(plainText: String, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
//        var error: NSError?
//
//        let newKey = CryptoNewKey(binKey.mutable as Data, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainText)
//
//        var signerKeyRing: KeyRing?
//        if !signerPrivateKey.isEmpty {
//            let signerKey = CryptoNewKeyFromArmored(signerPrivateKey, &error)
//            if let err = error {
//                throw err
//            }
//
//            let passSlic = passphrase.data(using: .utf8)
//            let unlockedSignerKey = try signerKey?.unlock(passSlic)
//
//            signerKeyRing = CryptoNewKeyRing(unlockedSignerKey, &error)
//            if let err = error {
//                throw err
//            }
//        }
//
//        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
//        let armoredMessage = cryptedMessage?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return armoredMessage
//    }
//
//    public func encrypt(plainText: String, publicKey binKey: Data) throws -> String? {
//        var error: NSError?
//
//        let newKey = CryptoNewKey(binKey.mutable as Data, &error)
//        if let err = error {
//            throw err
//        }
//
//        guard let key = newKey else {
//            return nil
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainText)
//
//        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: nil)
//        let armoredMessage = cryptedMessage?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return armoredMessage
//    }
//
//    // MARK: - encrypt with password
//    public func encrypt(plainText: String, token: String) throws -> String? {
//        let plainTextMessage = CryptoNewPlainMessageFromString(plainText)
//        let tokenBytes = token.data(using: .utf8)
//        var error: NSError?
//        let encryptedMessage = CryptoEncryptMessageWithPassword(plainTextMessage, tokenBytes, &error)
//        if let err = error {
//            throw err
//        }
//
//        let armoredMessage = encryptedMessage?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//        return armoredMessage
//    }
//
//    public func decrypt(encrypted: String, token: String) throws -> String? {
//        let tokenBytes = token.data(using: .utf8)
//        var error: NSError?
//        let pgpMsg = CryptoNewPGPMessageFromArmored(encrypted, &error)
//        if let err = error {
//            throw err
//        }
//        let message = CryptoDecryptMessageWithPassword(pgpMsg, tokenBytes, &error)
//        if let err = error {
//            throw err
//        }
//        return message?.getString()
//    }
//
// MARK: - Attachment
//
//     // no verify
//    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey: String, passphrase: String) throws -> Data? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
//        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
//        return plainMessage?.getBinary()
//    }
//
//    public func decryptAttachment1(splitMessage: SplitMessage, privateKey: String, passphrase: String) throws -> Data? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
//        return plainMessage?.getBinary()
//    }
//
//    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey binKeys: [Data], passphrase: String) throws -> Data? {
//        for binKey in binKeys {
//            do {
//                var error: NSError?
//                let key = CryptoNewKey(binKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                let passSlic = passphrase.data(using: .utf8)
//                let unlockedKey = try key?.unlock(passSlic)
//                let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
//                let plainMessage = try keyRing?.decryptAttachment(splitMessage)
//                return plainMessage?.getBinary()
//            } catch {
//                continue
//            }
//        }
//        return nil
//    }
//
//    public func decryptAttachment(encrypted: String, privateKey: String, passphrase: String) throws -> Data? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let splitMessage = CryptoNewPGPSplitMessageFromArmored(encrypted, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
//        return plainMessage?.getBinary()
//    }
//
//    public func encryptAttachment(plainData: Data, fileName: String, publicKey: String) throws -> SplitMessage? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let keyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let splitMessage = HelperEncryptAttachment(plainData, fileName, keyRing, &error)//without mutable
//        if let err = error {
//            throw err
//        }
//        return splitMessage
//    }
//
//    public func encryptAttachmentLowMemory(fileName:String, totalSize: Int, publicKey: String) throws -> AttachmentProcessor {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let keyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let processor = try keyRing!.newLowMemoryAttachmentProcessor(totalSize, filename: fileName)
//        return processor
//    }
//
//
//
//    public func signDetached(plainData: Data, privateKey: String, passphrase: String) throws -> String? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
//        let pgpSignature = try keyRing?.signDetached(plainMessage)
//        let signature = pgpSignature?.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return signature
//    }
//
//    public func signDetached(plainData: String, privateKey: String, passphrase: String) throws -> String {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainData)
//        let pgpSignature = try keyRing!.signDetached(plainMessage)
//        let signature = pgpSignature.getArmored(&error)
//        if let err = error {
//            throw err
//        }
//
//        return signature
//     }
//
//    public func verifyDetached(signature: String, plainData: Data, publicKey: String, verifyTime: Int64) throws -> Bool {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
//        let signature = CryptoNewPGPSignatureFromArmored(signature, &error)
//        if let err = error {
//            throw err
//        }
//
//        do {
//            try publicKeyRing?.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
//            return true
//        } catch {
//            return false
//        }
//    }
//
//    public func verifyDetached(signature: String, plainText: String, publicKey: String, verifyTime: Int64) throws -> Bool {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(publicKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let publicKeyRing = CryptoNewKeyRing(key, &error)
//        if let err = error {
//            throw err
//        }
//
//        let plainMessage = CryptoNewPlainMessageFromString(plainText)
//        let signature = CryptoNewPGPSignatureFromArmored(signature, &error)
//        if let err = error {
//            throw err
//        }
//
//        do {
//            try publicKeyRing?.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
//            return true
//        } catch {
//            return false
//        }
//    }
//
//    // MARK: - Session
//
//    //key packet part
//    public func getSession(keyPacket: Data, privateKeys binKeys: [Data], passphrase: String) throws -> SymmetricKey? {
//        for binKey in binKeys {
//            do {
//                var error: NSError?
//                let key = CryptoNewKey(binKey.mutable as Data, &error)
//                if error != nil {
//                    continue
//                }
//
//                let passSlic = passphrase.data(using: .utf8)
//                let unlockedKey = try key?.unlock(passSlic)
//
//                let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//                if error != nil {
//                    continue
//                }
//
//                let sessionKey = try keyRing?.decryptSessionKey(keyPacket.mutable as Data)
//                return sessionKey
//            } catch {
//                continue
//            }
//        }
//        return nil
//    }
//
//    public func getSession(keyPacket: Data, privateKey: String, passphrase: String) throws -> SymmetricKey? {
//        var error: NSError?
//        let key = CryptoNewKeyFromArmored(privateKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let passSlic = passphrase.data(using: .utf8)
//        let unlockedKey = try key?.unlock(passSlic)
//
//        let keyRing = CryptoNewKeyRing(unlockedKey, &error)
//        if let err = error {
//            throw err
//        }
//
//        let sessionKey = try keyRing?.decryptSessionKey(keyPacket.mutable as Data)
//        return sessionKey
//    }
//
//
//
//    // MARK: - static
//
//    static func updateTime( _ time : Int64) {
//        CryptoUpdateTime(time)
//    }
//
//    static func updatePassphrase(privateKey: String, oldPassphrase: String, newPassphrase: String) throws -> String {
//        var error: NSError?
//        let oldPassSlic = oldPassphrase.data(using: .utf8)
//        let newPassSlic = newPassphrase.data(using: .utf8)
//        let newKey = HelperUpdatePrivateKeyPassphrase(privateKey, oldPassSlic, newPassSlic, &error)
//        if let err = error {
//            throw err
//        }
//
//        return newKey
//    }
//
//    static func random(byte: Int) throws -> Data {
//        var error: NSError?
//        let data = CryptoRandomToken(byte, &error)
//        if let err = error {
//            throw err
//        }
//        guard let randomData = data else {
//            fatalError()
//        }
//        return randomData
//    }
//
//    func buildKeyRing(keys: [Data]) -> CryptoKeyRing? {
//        var error: NSError?
//        let newKeyRing = CryptoNewKeyRing(nil, &error)
//        guard let keyRing = newKeyRing else {
//            return nil
//        }
//        for key in keys {
//            do {
//                if let keyToAdd = CryptoNewKey(key, &error) {
//                    try keyRing.add(keyToAdd)
//                }
//            } catch {
//                continue
//            }
//        }
//        return keyRing
//    }
//
//    func buildPrivateKeyRing(keys: [Data], passphrase: String) -> CryptoKeyRing? {
//        var error: NSError?
//        let newKeyRing = CryptoNewKeyRing(nil, &error)
//        guard let keyRing = newKeyRing else {
//            return nil
//        }
//        let passSlic = passphrase.data(using: .utf8)
//
//        for key in keys {
//            do {
//                if let unlockedKey = try CryptoNewKey(key, &error)?.unlock(passSlic) {
//                    try keyRing.add(unlockedKey)
//                }
//            } catch {
//                continue
//            }
//        }
//        return keyRing
//    }
// }
