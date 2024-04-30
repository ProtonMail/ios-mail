//
//  Decryptor.swift
//  ProtonCore-KeyManager - Created on 18/03/2021.
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
import ProtonCoreUtilities

///
public class DecryptionAddress {
    ///
    /// - Parameters:
    ///   - userBinKeys: user key bin array
    ///   - passphrase: user key's passpharse. on v1.0 also could be address key passphrase
    ///   - addressKeys: user email address keys
    public init(userBinKeys: [Data], passphrase: String, addressKeys: [Key]) {
        self.userBinKeys = userBinKeys
        self.passphrase = passphrase
        self.addressKeys = addressKeys
    }

    public let userBinKeys: [Data]
    public let passphrase: String
    public let addressKeys: [Key]
}

/// TODO:: rename
public class DecryptionKey {
    ///
    /// - Parameters:
    ///   - privateKey:  address key for signing.  calendar key for decryption. folder key for decrypton
    ///   - passphrase:
    public init(privateKey: String, passphrase: String) {
        self.privateKey = privateKey
        self.passphrase = passphrase
    }

    public let privateKey: String
    public let passphrase: String
}

@available(*, deprecated, message: "please to use ProtonCore-Crypto module Decryptor")
public enum Decryptor {
    public enum Errors: Error {
        case emptyResult
        case notString
        case noParentPacket
        case failedToFormSplit
        case failedToOpenPGPMessage
        case invalidPassphraseFormat
        case noValidKeyFound
        case couldNotCreateKeyRing
        case noKeyCouldBeUnlocked(errors: [Error])
        case invalidSessionKey
        case noPGPMessageFound
        case outputFileAlreadyExists
    }

    @available(*, deprecated, renamed: "Decryptor.decrypt(decryptionKeys:value:)")
    public static func decrypt(encValue: String, decryptionKeys: [DecryptionKey]) throws -> String {
        try decrypt(decryptionKeys: decryptionKeys, value: encValue)
    }

    public static func decrypt(decryptionKeys: [DecryptionKey], value: String) throws -> String {
        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }

        guard let pgpMsg = CryptoGo.CryptoPGPMessage(fromArmored: value) else {
            throw NSError(domain: "Invalid messge", code: 0)
        }
        let plainMsg = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGo.CryptoGetUnixTime())
        let plaintext = plainMsg.getString()
        return plaintext
    }

    // Check if this can be part of a future Decryptor protocol
    static func decryptAndVerify(verificationKeys: [String],
                                 decryptionKeys: [DecryptionKey],
                                 value: String) throws -> String {
        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }

        let verificationKeyRing = try buildPublicKeyRing(armoredKeys: verificationKeys)
        let pgpMsg = CryptoGo.CryptoPGPMessage(fromArmored: value)
        let plainMsg = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: verificationKeyRing, verifyTime: CryptoGo.CryptoGetUnixTime())
        let plaintext = plainMsg.getString()
        return plaintext
    }

    // Can be made private
    static func decryptAndVerifyDetached(verificationKeys: [String],
                                         decryptionKeys: [DecryptionKey],
                                         armoredCiphertext: String,
                                         armoredSignature: String) throws -> CryptoPlainMessage {
        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }

        let verificationKeyRing = try buildPublicKeyRing(armoredKeys: verificationKeys)
        let pgpMsg = CryptoGo.CryptoPGPMessage(fromArmored: armoredCiphertext)
        let plainMsg = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGo.CryptoGetUnixTime())

        let pgpSignature = CryptoGo.CryptoPGPSignature(fromArmored: armoredSignature)
        try verificationKeyRing?.verifyDetached(plainMsg, signature: pgpSignature, verifyTime: CryptoGo.CryptoGetUnixTime())

        return plainMsg
    }

    // Can be made private
    static func decryptAndVerifyDetachedEncrypted(verificationKeys: [String],
                                                  decryptionKeys: [DecryptionKey],
                                                  pgpMsg: CryptoPGPMessage,
                                                  encryptedSignature: String) throws -> CryptoPlainMessage {
        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }

        let verificationKeyRing = try buildPublicKeyRing(armoredKeys: verificationKeys)
        let plainMsg = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGo.CryptoGetUnixTime())
        let pgpEncSignature = CryptoGo.CryptoPGPMessage(fromArmored: encryptedSignature)
        try verificationKeyRing?.verifyDetachedEncrypted(plainMsg, encryptedSignature: pgpEncSignature, decryptionKeyRing: decryptionKeyRing, verifyTime: CryptoGo.CryptoGetUnixTime())
        return plainMsg
    }

    static func decryptBinary(keyPacket: Data,
                              dataPacket: Data,
                              decryptionKeys: [DecryptionKey]) throws -> Data {

        guard let pgpMsg = CryptoGo.CryptoPGPSplitMessage(keyPacket, dataPacket: dataPacket)?.getPGPMessage() else {
            throw Errors.noPGPMessageFound
        }

        let plainMsg = try decryptDetachedEncrypted(decryptionKeys: decryptionKeys, pgpMsg: pgpMsg)

        guard let binary = plainMsg.getBinary() else { throw Errors.emptyResult }

        return binary
    }

    public static func decryptAndVerifyBinary(cypherData: Data,
                                              contentKeyPacket: Data,
                                              privateKey: String,
                                              passphrase: String,
                                              verificationKeys: [String]) throws -> Data {
        var error: NSError?

        let newSessionKey = CryptoGo.HelperDecryptSessionKey(privateKey, passphrase.data(using: .utf8), contentKeyPacket, &error)
        guard error == nil else { throw error! }
        guard let sessionKey = newSessionKey else { throw Errors.invalidSessionKey }

        let keyRing = try buildPublicKeyRing(armoredKeys: verificationKeys)

        let message = try sessionKey.decryptAndVerify(cypherData, verifyKeyRing: keyRing, verifyTime: CryptoGo.CryptoGetUnixTime())

        guard let binary = message.getBinary() else { throw Errors.emptyResult }

        return binary
    }

    static func decryptDetachedEncrypted(decryptionKeys: [DecryptionKey], pgpMsg: CryptoPGPMessage) throws -> CryptoPlainMessage {
        let decryptionKeyRing = try buildPrivateKeyRing(with: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }

        let plainMsg = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGo.CryptoGetUnixTime())
        return plainMsg
    }

    public static func decryptBinary(keyPacket: Data, // crypto key packet
                                     dataPacket: Data, // cyphertext
                                     decryptionKeys: [DecryptionKey],
                                     encSignature: String,
                                     verificationKeys: [String]) throws -> Data {

        guard let pgpMsg = CryptoGo.CryptoPGPSplitMessage(keyPacket, dataPacket: dataPacket)?.getPGPMessage() else {
            throw Errors.noPGPMessageFound
        }

        let plainMsg = try decryptAndVerifyDetachedEncrypted(
            verificationKeys: verificationKeys,
            decryptionKeys: decryptionKeys,
            pgpMsg: pgpMsg,
            encryptedSignature: encSignature)

        guard let binary = plainMsg.getBinary() else { throw Errors.emptyResult }

        return binary
    }

    public static func decryptSessionKey(of cyphertext: String,
                                         privateKey: String,
                                         passphrase: String) throws -> CryptoSessionKey {
        let splitMessage = CryptoGo.CryptoPGPSplitMessage(fromArmored: cyphertext)
        let keyPacket = splitMessage?.keyPacket

        var error: NSError?
        let sessionKey = CryptoGo.HelperDecryptSessionKey(privateKey, passphrase.data(using: .utf8), keyPacket, &error)
        guard error == nil else { throw error! }
        guard let unwrappedSessionKey = sessionKey else { throw Errors.invalidSessionKey }

        return unwrappedSessionKey
    }
}

extension Decryptor {
    public static func decryptNewKey(token: String,
                                     userKey: String,
                                     passphrase: String,
                                     signature: String) throws -> String {
        try decryptPassphrase(
            verificationKeys: [userKey],
            decryptionKeys: [DecryptionKey(privateKey: userKey, passphrase: passphrase)],
            armoredCyphertext: token,
            armoredSignature: signature
        )
    }

    public static func decryptPassphrase(verificationKeys: [String],
                                         decryptionKeys: [DecryptionKey],
                                         armoredCyphertext: String,
                                         armoredSignature: String) throws -> String {
        try decryptAndVerifyDetached(
            verificationKeys: verificationKeys,
            decryptionKeys: decryptionKeys,
            armoredCiphertext: armoredCyphertext,
            armoredSignature: armoredSignature
        ).getString()
    }
}

// MARK: - CryptoKeyRing decryption helpers
extension Decryptor {
    public static func buildPublicKeyRing(armoredKeys: [String]) throws -> CryptoKeyRing? {
        var error: NSError?
        let newKeyRing = CryptoGo.CryptoNewKeyRing(nil, &error)
        guard let keyRing = newKeyRing else { return nil }
        for armoredKey in armoredKeys {
            let keyToAdd = CryptoGo.CryptoNewKeyFromArmored(armoredKey, &error)
            guard error == nil else { throw error! }
            if keyToAdd?.isPrivate() == true {
                let publicKey = try keyToAdd?.toPublic()
                try keyRing.add(publicKey)
            } else {
                try keyRing.add(keyToAdd)
            }
        }
        return keyRing
    }

    public static func buildPublicKeyRing(binKeys: [Data]) throws -> CryptoKeyRing? {
        var error: NSError?
        let newKeyRing = CryptoGo.CryptoNewKeyRing(nil, &error)
        guard let keyRing = newKeyRing else { return nil }
        for binKey in binKeys {
            let keyToAdd = CryptoGo.CryptoNewKey(binKey, &error)
            guard error == nil else { throw error! }
            if keyToAdd?.isPrivate() == true {
                let publicKey = try keyToAdd?.toPublic()
                try keyRing.add(publicKey)
            } else {
                try keyRing.add(keyToAdd)
            }
        }
        return keyRing
    }
}

// MARK: - CryptoKeyRing decryption helpers
extension Decryptor {

    public static func buildPrivateKeyRing(with decryptionKeys: [DecryptionKey]) throws -> CryptoKeyRing {
        var error: NSError?
        var unlockKeyErrors = [Error]()
        let newKeyRing = CryptoGo.CryptoNewKeyRing(nil, &error)
        if let error = error { throw error }
        guard let keyRing = newKeyRing else { throw Errors.couldNotCreateKeyRing }

        for decryptionKey in decryptionKeys {
            let passphrase = decryptionKey.passphrase.utf8 // Data(from: decryptionKey.passphrase as! Decoder)
            let lockedKey = CryptoGo.CryptoNewKeyFromArmored(decryptionKey.privateKey, &error)
            if let error = error { throw error }
            do {
                let unlockedKey = try lockedKey?.unlock(passphrase)
                try keyRing.add(unlockedKey)
            } catch let failure {
                unlockKeyErrors.append(failure)
                continue
            }
        }

        guard unlockKeyErrors.count != decryptionKeys.count else {
            throw Errors.noKeyCouldBeUnlocked(errors: unlockKeyErrors)
        }

        return keyRing
    }
}

// the calendar part
extension Decryptor {

    public static func getMemberPassphrase(privateKey: String,
                                           privateKeyPassphrase: String,
                                           encMemberPassphrase: String, error: inout NSError?) -> String {
        CryptoGo.HelperDecryptMessageArmored(privateKey,
                                             privateKeyPassphrase.data(using: .utf8),
                                             encMemberPassphrase,
                                             &error)
    }

    public static func getMemberPassphrase(keyring: CryptoKeyRing, encMemberPassphrase: String) throws -> String {
        let message = CryptoGo.CryptoPGPMessage(fromArmored: encMemberPassphrase)
        let decryptedMsg = try keyring.decrypt(message,
                                               verifyKey: nil,
                                               verifyTime: CryptoGo.CryptoGetUnixTime())
        return decryptedMsg.getString()
    }

    public static func getMemberPassphrase(privateKey: String,
                                           privateKeyPassphrase: String,
                                           encMemberPassphrase: String) throws -> String {
        var error: NSError?
        let out = CryptoGo.HelperDecryptMessageArmored(privateKey,
                                                       privateKeyPassphrase.data(using: .utf8),
                                                       encMemberPassphrase,
                                                       &error)
        if let err = error {
            throw err
        }
        return out
    }

    /// decrypt a encrypted passpharse use address key
    /// - Parameters:
    ///   - encPassphrase:
    ///   - decryption:
    /// - Throws:
    /// - Returns:
    public static func decryptPassphrase(encPassphrase: String, decryption: DecryptionAddress) throws -> String {
        for key in decryption.addressKeys {
            do {
                let clear = try key.passphrase(userPrivateKeys: decryption.userBinKeys.toArmored,
                                               mailboxPassphrase: Passphrase.init(value: decryption.passphrase))
                var error: NSError?
                let out = CryptoGo.HelperDecryptMessageArmored(key.privateKey,
                                                               clear.data,
                                                               encPassphrase, &error)
                if let err = error {
                    throw err
                }
                return out
            } catch {

            }
        }
        throw Errors.emptyResult
    }

    @available(*, deprecated, message: "deprecated")
    func getMemberPassphrase(privateKey: String, privateKeyPassphrase: String, encMemberPassphrase: String, error: inout NSError?) -> String {
        CryptoGo.HelperDecryptMessageArmored(privateKey,
                                             privateKeyPassphrase.data(using: .utf8),
                                             encMemberPassphrase,
                                             &error)
    }

    @available(*, deprecated, message: "deprecated")
    public static func getMemberPassphrase(encPassphrase: String, keyring: CryptoKeyRing) throws -> String {
        let message = CryptoGo.CryptoPGPMessage(fromArmored: encPassphrase)
        let decryptedMsg = try keyring.decrypt(message,
                                               verifyKey: nil,
                                               verifyTime: CryptoGo.CryptoGetUnixTime())

        return decryptedMsg.getString()
    }

    /**
     If no signature is passed in, we count it as a verification failed
     */
    public static func decryptAndVerifySignature(keyPacket: Data,
                                                 dataPacket: Data,
                                                 signature: String?,
                                                 verifyTime: Int64,
                                                 decryptionKeyRing: CryptoKeyRing,
                                                 signatureKeyRing: [CryptoKeyRing],
                                                 signatureKeyRingIndex: inout Int) throws -> (str: String, isValid: Bool) {
        var err: NSError?

        let str = Decryptor.decryptString(keyPacket: keyPacket,
                                          dataPacket: dataPacket,
                                          keyRing: decryptionKeyRing,
                                          error: &err)
        if let err = err {
            throw err
        }

        return try Decryptor.verifySignature(str: str,
                                             signature: signature,
                                             verifyTime: verifyTime,
                                             signatureKeyRing: signatureKeyRing,
                                             signatureKeyRingIndex: &signatureKeyRingIndex)
    }

    public static func decryptAndVerifySignature(keyPacket: Data,
                                                 dataPacket: Data,
                                                 signature: String?,
                                                 verifyTime: Int64,
                                                 decryptionKeyRing: CryptoKeyRing,
                                                 signatureKeyRing: CryptoKeyRing) throws -> (str: String, isValid: Bool)
    {
        var err: NSError?
        let str = Decryptor.decryptString(keyPacket: keyPacket,
                                          dataPacket: dataPacket,
                                          keyRing: decryptionKeyRing,
                                          error: &err)
        if let err = err {
            throw err
        }

        return try Decryptor.verifySignature(str: str,
                                             signature: signature,
                                             verifyTime: verifyTime,
                                             signatureKeyRing: signatureKeyRing)
    }

    /// decrypt and return string
    /// - Parameters:
    ///   - keyPacket: pgp keypacket
    ///   - dataPacket: pgp datapacket
    ///   - keyRing: decrypted keyRing
    ///   - error: crypto error/exception
    /// - Returns: Decrypted value : String type
    private static func decryptString(keyPacket: Data,
                                      dataPacket: Data,
                                      keyRing: CryptoKeyRing, error: inout NSError?) -> String {
        CryptoGo.HelperDecryptAttachment(keyPacket,
                                         dataPacket,
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

    public static func verifySignature(str: String, signature: String?,
                                       verifyTime: Int64,
                                       signatureKeyRing: CryptoKeyRing) throws -> (str: String, isValid: Bool) {
        if let signature = signature {
            return (str, try Decryptor.verifyDetached(signature: signature,
                                                      plainText: str,
                                                      keyRing: signatureKeyRing,
                                                      verifyTime: verifyTime))
        } else {
            return (str, true)
        }
    }

    private static func verifySignature(str: String, signature: String?,
                                        verifyTime: Int64,
                                        signatureKeyRing: [CryptoKeyRing],
                                        signatureKeyRingIndex: inout Int) throws -> (str: String, isValid: Bool) {
        if let signature = signature {
            var ok = false

            for _ in 0 ..< signatureKeyRing.count {
                let isValid = try Decryptor.verifyDetached(signature: signature,
                                                           plainText: str,
                                                           keyRing: signatureKeyRing[signatureKeyRingIndex],
                                                           verifyTime: verifyTime)
                if isValid {
                    ok = true
                    break
                } else {
                    signatureKeyRingIndex = (signatureKeyRingIndex + 1) % signatureKeyRing.count
                }
            }

            return (str, ok)
        } else {
            return (str, true)
        }
    }

}
