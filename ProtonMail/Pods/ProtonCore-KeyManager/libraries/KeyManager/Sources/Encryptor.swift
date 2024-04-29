//
//  Encryptor.swift
//  ProtonCore-KeyManager - Created on 03/04/2021.
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
import CommonCrypto
import ProtonCoreUtilities

@available(*, deprecated, message: "please to use ProtonCore-Crypto module encryptor")
public enum Encryptor {
    public typealias HashableString = String
    public typealias HashableData = Data

    public enum Errors: Error {
        case failedToCreateSimmetricKey
        case failedToUnarmor
        case invalidSessionKey
        case couldNotCreateKeyRing
        case couldNotCreateRandomToken
        case coldNotObtainKeyFromSessionKey
    }

    public struct ContentKeys {
        public let sessionKey: String
        public let contentKeyPacket: String
        public let contentKeyPacketSignature: String
    }

    public struct EncryptedBlock {
        public var data, hash: Data
    }

    public static func hmac(filename: String,
                            parentHashKey: String) throws -> String
    {
        return HashableString(filename).hmacSHA256(key: parentHashKey)
    }

    // generateHashKey generates a key that is used to produce HMACS of all the
    // filenames in the folder
    static func generateHashKey(nodeKey: String) throws -> String {
        var error: NSError?

        // length is hardcoded in proton-shared/lib/keys/calendarKeys.ts
        let hashKeyByteLength = 32
        let hashKeyRaw = CryptoGo.CryptoRandomToken(hashKeyByteLength, &error)
        guard error == nil else { throw error! }

        let key = CryptoGo.CryptoKey(fromArmored: nodeKey)!
        let publicKey = key.getArmoredPublicKey(&error)
        guard error == nil else { throw error! }

        let hashKey = hashKeyRaw!.base64EncodedString()
        let encrypted = CryptoGo.HelperEncryptMessageArmored(publicKey,
                                                             hashKey,
                                                             &error)
        guard error == nil else { throw error! }

        return encrypted
    }

    public static func encrypt(_ cleartext: String, key: String) throws -> String {
        var error: NSError?

        let name = CryptoGo.HelperEncryptMessageArmored(key, cleartext, &error)
        guard error == nil else { throw error! }

        return name
    }

    public static func encryptAndSign(_ cleartext: String,
                                      key: String,
                                      addressPassphrase: String,
                                      addressPrivateKey: String) throws -> String
    {
        var error: NSError?

        let name = CryptoGo.HelperEncryptSignMessageArmored(key, addressPrivateKey, addressPassphrase.data(using: .utf8), cleartext, &error)
        guard error == nil else { throw error! }

        return name
    }

    public static func generateContentKeys(nodeKey: String,
                                           addressPrivateKey: String,
                                           addressPassphrase: String) throws -> ContentKeys {
        var error: NSError?

        // 1. create session key
        let sessionKey = CryptoGo.CryptoGenerateSessionKeyAlgo("aes256", &error)
        guard error == nil else { throw error! }

        // 2. encrypt session key with public key
        let encrypted = CryptoGo.HelperEncryptSessionKey(nodeKey,
                                                         sessionKey,
                                                         &error)
        guard error == nil else { throw error! }

        // 3. encode encrypted session key to base64
        let contentKeyPacket = encrypted?.base64EncodedString()

        // 4. obtain signature

        let contentKeyPacketSignature = try sign(list: encrypted!, addressKey: addressPrivateKey, addressPassphrase: addressPassphrase)

        // 5. serialize
        return ContentKeys(sessionKey: sessionKey!.getBase64Key(),
                           contentKeyPacket: contentKeyPacket!,
                           contentKeyPacketSignature: contentKeyPacketSignature)
    }

    public static func encryptBinary(chunk: Data,
                                     contentKeyPacket: Data,
                                     nodeKey: String,
                                     nodePassphrase: String) throws -> EncryptedBlock
    {
        var error: NSError?

        let message = CryptoGo.CryptoNewPlainMessage(chunk)
        let sessionKey = CryptoGo.HelperDecryptSessionKey(nodeKey,
                                                          nodePassphrase.utf8,
                                                          contentKeyPacket,
                                                          &error)
        guard error == nil else { throw error! }

        let encrypted = try sessionKey?.encrypt(message)
        guard error == nil else { throw error! }

        let hash = encrypted!.hashSha256()

        return .init(data: encrypted!, hash: hash)
    }

    public static func sign(list: Data,
                            addressKey: String,
                            addressPassphrase: String) throws -> String
    {
        var error: NSError?

        let signatureArmored = try produceSignature(plaintext: list, privateKey: addressKey, passphrase: addressPassphrase).getArmored(&error)
        guard error == nil else { throw error! }

        return signatureArmored
    }

    public static func signcrypt(plaintext: Data,
                                 nodeKey: String,
                                 addressKey: String,
                                 addressPassphrase: String) throws -> String
    {
        var error: NSError?

        let signatureData = try produceSignature(plaintext: plaintext, privateKey: addressKey, passphrase: addressPassphrase).getBinary()

        let encSignature = CryptoGo.HelperEncryptBinaryMessageArmored(nodeKey, signatureData, &error)
        guard error == nil else { throw error! }

        return encSignature
    }

    private static func produceSignature(plaintext: Data,
                                         privateKey: String,
                                         passphrase: String) throws -> CryptoPGPSignature
    {
        var error: NSError?

        let keyAddress = CryptoGo.CryptoNewKeyFromArmored(privateKey, &error)
        guard error == nil else { throw error! }

        let unlockedKey = try keyAddress?.unlock(passphrase.data(using: .utf8))
        let keyRing = CryptoGo.CryptoNewKeyRing(unlockedKey, &error)
        guard error == nil else { throw error! }

        let message = CryptoGo.CryptoNewPlainMessage(plaintext)
        let signature = try keyRing?.signDetached(message)
        keyRing?.clearPrivateParams()
        return signature!
    }

    public static func encryptSessionKey(_ sessionKey: CryptoSessionKey, withKey: String) throws -> String {
        var error: NSError!
        let encrypted = CryptoGo.HelperEncryptSessionKey(withKey, sessionKey, &error)
        guard error == nil else { throw error! }

        return encrypted!.base64EncodedString()
    }

    static func signDetached(plainText: String, privateKey: String, passphrase: String) throws -> String {
        try signDetached(input: .left(plainText), privateKey: privateKey, passphrase: passphrase)
    }

    static func signDetached(plainData: Data, privateKey: String, passphrase: String) throws -> String {
        try signDetached(input: .right(plainData), privateKey: privateKey, passphrase: passphrase)
    }

    private static func signDetached(input: Either<String, Data>, privateKey: String, passphrase: String) throws -> String {

        var error: NSError?
        let keyAddress = CryptoGo.CryptoNewKeyFromArmored(privateKey, &error)
        guard error == nil else { throw error! }

        let unlockedKey = try keyAddress?.unlock(passphrase.data(using: .utf8))
        let keyRing = CryptoGo.CryptoNewKeyRing(unlockedKey, &error)
        guard error == nil else { throw error! }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText.trimTrailingSpaces())
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }

        let pgpSignature = try keyRing?.signDetached(plainMessage)
        keyRing?.clearPrivateParams()
        let signaure = pgpSignature?.getArmored(&error)
        guard error == nil else { throw error! }

        return signaure!
    }
}

public typealias ArmoredSignature = String

// for calendar
extension Encryptor {

    /// sign the string as detached signature
    /// - Parameters:
    ///   - plainText: plantext value
    ///   - keyRing: the signer key ring
    /// - Throws: Crypto exception or error
    /// - Returns: Signautue
    public static func signDetached(plainText: String, keyRing: CryptoKeyRing) throws -> ArmoredSignature {
        try signDetached(input: .left(plainText), keyRing: keyRing)
    }

    public static func signDetached(plainData: Data, keyRing: CryptoKeyRing) throws -> ArmoredSignature {
        try signDetached(input: .right(plainData), keyRing: keyRing)
    }

    private static func signDetached(input: Either<String, Data>, keyRing: CryptoKeyRing) throws -> ArmoredSignature {
        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText.trimTrailingSpaces())
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }
        let pgpSignature = try keyRing.signDetached(plainMessage)
        var error: NSError?
        let signaure = pgpSignature.getArmored(&error)
        if let err = error {
            throw err
        }
        return signaure
    }

    public static func encrypt(plainText: String,
                               keyRing: CryptoKeyRing,
                               signerKeyRing: CryptoKeyRing?) throws -> (key: String, data: String) {
        try encrypt(input: .left(plainText), keyRing: keyRing, signerKeyRing: signerKeyRing)
    }

    public static func encrypt(plainData: Data,
                               keyRing: CryptoKeyRing,
                               signerKeyRing: CryptoKeyRing?) throws -> (key: String, data: String) {
        try encrypt(input: .right(plainData), keyRing: keyRing, signerKeyRing: signerKeyRing)
    }

    private static func encrypt(input: Either<String, Data>,
                                keyRing: CryptoKeyRing,
                                signerKeyRing: CryptoKeyRing?) throws -> (key: String, data: String) {
        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText.trimTrailingSpaces())
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }

        let encryptedMessage = try keyRing.encrypt(plainMessage, privateKey: signerKeyRing)

        let split = try encryptedMessage.splitMessage()

        return (split.keyPacket!.base64EncodedString(), split.dataPacket!.base64EncodedString()) // FIXME:
    }
}

extension Encryptor {

    @available(*, deprecated, renamed: "encryptAndSignBinary(plainData:contentKeyPacket:privateKey:passphrase:addressKey:addressPassphrase:)")
    public static func encryptAndSignBinary(clearData: Data, contentKeyPacket: Data, privateKey: String, passphrase: String, addressKey: String, addressPassphrase: String) throws -> EncryptedBlock {
        try encryptAndSignBinary(plainData: clearData, contentKeyPacket: contentKeyPacket, privateKey: privateKey,
                                 passphrase: passphrase, addressKey: addressKey, addressPassphrase: addressPassphrase)
    }

    public static func encryptAndSignBinary(plainData: Data, contentKeyPacket: Data, privateKey: String, passphrase: String, addressKey: String, addressPassphrase: String) throws -> EncryptedBlock {
        var error: NSError?
        let message = CryptoGo.CryptoNewPlainMessage(plainData)

        let newSessionKey = CryptoGo.HelperDecryptSessionKey(privateKey, passphrase.data(using: .utf8), contentKeyPacket, &error)
        guard error == nil else { throw error! }
        guard let sessionKey = newSessionKey else { throw Errors.invalidSessionKey }

        let keyRing = try Decryptor.buildPrivateKeyRing(with: [.init(privateKey: addressKey, passphrase: addressPassphrase)])

        let encrypted = try sessionKey.encryptAndSign(message, sign: keyRing)
        let hash = encrypted.hashSha256()

        return EncryptedBlock(data: encrypted, hash: hash)
    }
}
