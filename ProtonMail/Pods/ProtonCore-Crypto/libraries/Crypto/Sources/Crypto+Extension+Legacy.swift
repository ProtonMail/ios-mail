//
//  Crypto+Extension+Legacy.swift
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
import ProtonCore_Utilities

// Helper
extension Crypto {
    
    @available(*, deprecated, message: "Will not return empty String anymore, please update to variant without typo")
    public func decrypt(encrytped message: String, privateKey: String, passphrase: String) throws -> String {
        do {
            return try decrypt(encrypted: message, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.couldNotCreateKey {
            return ""
        } catch CryptoError.messageCouldNotBeDecrypted {
            return ""
        } catch {
            throw error
        }
    }

    // no verify
    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decrypt(encrypted message: String, privateKey: String, passphrase: String) throws -> String {

        let newKey = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        guard let key = newKey else { throw CryptoError.couldNotCreateKey }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key.unlock(passSlice)

        let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }
        let pgpMsg = try throwing { error in CryptoNewPGPMessageFromArmored(message, &error) }

        guard let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGetUnixTime()).getString() else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        return plainMessageString
    }

    @available(*, deprecated, message: "Will not return empty String anymore, please update to variant without typo")
    func decrypt(encrytped message: String, privateKey binKeys: [Data], passphrase: String) throws -> String {
        do {
            return try decrypt(encrypted: message, privateKeys: binKeys, passphrase: passphrase)
        } catch CryptoError.couldNotCreateKey {
            return ""
        } catch CryptoError.messageCouldNotBeDecrypted {
            return ""
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    func decrypt(encrypted message: String, privateKeys binKeys: [Data], passphrase: String) throws -> String {
        for binKey in binKeys {
            do {
                let newKey = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

                guard let key = newKey else {
                    continue
                }

                let passSlice = passphrase.data(using: .utf8)
                let unlockedKey = try key.unlock(passSlice)

                let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

                let pgpMsg = try throwing { error in CryptoNewPGPMessageFromArmored(message, &error) }

                guard let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGetUnixTime()).getString() else {
                    throw CryptoError.messageCouldNotBeDecrypted
                }
                return plainMessageString
            } catch {
                continue
            }
        }
        throw CryptoError.messageCouldNotBeDecrypted
    }

    @available(*, deprecated, message: "Will not return empty String anymore, please update to variant without typo")
    func decrypt(encrytped binMessage: Data, privateKey: String, passphrase: String) throws -> String {
        do {
            return try decrypt(encrypted: binMessage, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.couldNotCreateKey {
            return ""
        } catch CryptoError.messageCouldNotBeDecrypted {
            return ""
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    func decrypt(encrypted binMessage: Data, privateKey: String, passphrase: String) throws -> String {
        let newKey = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        guard let key = newKey else {
            throw CryptoError.couldNotCreateKey
        }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key.unlock(passSlice)

        let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let pgpMsg = CryptoNewPGPMessage(binMessage.mutable as Data)

        guard let plainMessageString = try privateKeyRing?.decrypt(pgpMsg, verifyKey: nil, verifyTime: CryptoGetUnixTime()).getString() else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        return plainMessageString
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decrypt(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey binKeys: [Data],
                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
        do {
            return try decryptNonOptional(encrypted: message,
                                          publicKey: verifierBinKey,
                                          privateKey: binKeys,
                                          passphrase: passphrase,
                                          verifyTime: verifyTime)
        } catch CryptoError.messageCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptNonOptional(encrypted message: String,
                                   publicKey verifierBinKey: Data,
                                   privateKey binKeys: [Data],
                                   passphrase: String,
                                   verifyTime: Int64) throws -> CryptoPlainMessage {

        for binKey in binKeys {
            do {
                let newKey = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

                guard let key = newKey else {
                    continue
                }

                let passSlice = passphrase.data(using: .utf8)
                let unlockedKey = try key.unlock(passSlice)

                let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

                let verifierKey = try throwing { error in CryptoNewKey(verifierBinKey.mutable as Data, &error) }

                let verifierKeyRing = try throwing { error in CryptoNewKeyRing(verifierKey, &error) }

                let pgpMsg = CryptoPGPMessage(fromArmored: message)

                guard let plainMessage = try privateKeyRing?.decrypt(pgpMsg, verifyKey: verifierKeyRing, verifyTime: verifyTime) else {
                    throw CryptoError.messageCouldNotBeDecrypted
                }
                return plainMessage
            } catch {
                continue
            }
        }
        throw CryptoError.messageCouldNotBeDecrypted
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decrypt(encrytped message: String,
                        publicKey verifierBinKey: Data,
                        privateKey armorKey: String,
                        passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage? {
        do {
            return try decryptNonOptional(encrypted: message,
                                          publicKey: verifierBinKey,
                                          privateKey: armorKey,
                                          passphrase: passphrase,
                                          verifyTime: verifyTime)
        } catch CryptoError.messageCouldNotBeDecrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptNonOptional(encrypted message: String,
                                   publicKey verifierBinKey: Data,
                                   privateKey armorKey: String,
                                   passphrase: String, verifyTime: Int64) throws -> CryptoPlainMessage {
        let newKey = try throwing { error in CryptoNewKeyFromArmored(armorKey, &error) }

        guard let key = newKey else { throw CryptoError.couldNotCreateKey }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key.unlock(passSlice)

        let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let verifierKey = try throwing { error in CryptoNewKey(verifierBinKey.mutable as Data, &error) }

        let verifierKeyRing = try throwing { error in CryptoNewKeyRing(verifierKey, &error) }

        let pgpMsg = CryptoPGPMessage(fromArmored: message)

        guard let plainMessage = try privateKeyRing?.decrypt(pgpMsg, verifyKey: verifierKeyRing, verifyTime: verifyTime) else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        return plainMessage
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptVerify(encrytped message: String,
                              publicKey verifierBinKeys: [Data],
                              privateKey armorKey: String,
                              passphrase: String,
                              verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        do {
            return try decryptVerifyNonOptional(encrypted: message,
                                                publicKey: verifierBinKeys,
                                                privateKey: armorKey,
                                                passphrase: passphrase,
                                                verifyTime: verifyTime)
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch CryptoError.messageCouldNotBeDecryptedWithExplicitVerification {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptVerifyNonOptional(encrypted message: String,
                                         publicKey verifierBinKeys: [Data],
                                         privateKey armorKey: String,
                                         passphrase: String,
                                         verifyTime: Int64) throws -> ExplicitVerifyMessage {

        let newKey = try throwing { error in CryptoNewKeyFromArmored(armorKey, &error) }

        guard let key = newKey else { throw CryptoError.couldNotCreateKey }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key.unlock(passSlice)

        let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let verifierKeyRing = try buildKeyRingNonOptional(adding: verifierBinKeys)

        let pgpMsg = CryptoPGPMessage(fromArmored: message)

        let verified = try throwing { error in HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error) }

        guard let verified = verified else { throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification }

        return verified
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptVerify(encrytped message: String,
                              publicKey verifierBinKeys: [Data],
                              privateKey binKeys: [Data],
                              passphrase: String, verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        do {
            return try decryptVerifyNonOptional(encrypted: message,
                                                publicKey: verifierBinKeys,
                                                privateKey: binKeys,
                                                passphrase: passphrase,
                                                verifyTime: verifyTime)
        } catch CryptoError.messageCouldNotBeDecryptedWithExplicitVerification {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptVerifyNonOptional(encrypted message: String,
                                         publicKey verifierBinKeys: [Data],
                                         privateKey binKeys: [Data],
                                         passphrase: String,
                                         verifyTime: Int64) throws -> ExplicitVerifyMessage {
        let privateKeyRing = try buildPrivateKeyRingNonOptional(adding: binKeys, passphrase: passphrase)
        let verifierKeyRing = try buildKeyRingNonOptional(adding: verifierBinKeys)

        let pgpMsg = CryptoPGPMessage(fromArmored: message)

        let verified = try throwing { error in HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error) }
        guard let verified = verified else {
            throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
        }
        return verified
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptVerify(encrypted message: String,
                              publicKeys verifierBinKeys: [Data],
                              privateKeys: [(privateKey: String, passphrase: String)],
                              verifyTime: Int64) throws -> ExplicitVerifyMessage {
        let privateKeyRing = try buildPrivateKeyRing(keys: privateKeys)
        let verifierKeyRing = try buildKeyRingNonOptional(adding: verifierBinKeys)

        let pgpMsg = try throwing { error in CryptoNewPGPMessageFromArmored(message, &error) }

        let verified = try throwing { error in HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error) }

        guard let verified = verified else {
            throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
        }

        return verified
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptVerify(encrytped message: String,
                              publicKey: String,
                              privateKey armorKey: String,
                              passphrase: String,
                              verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        do {
            return try decryptVerifyNonOptional(encrypted: message,
                                                publicKey: publicKey,
                                                privateKey: armorKey,
                                                passphrase: passphrase,
                                                verifyTime: verifyTime)
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch CryptoError.messageCouldNotBeDecryptedWithExplicitVerification {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptVerifyNonOptional(encrypted message: String,
                                         publicKey: String,
                                         privateKey armorKey: String,
                                         passphrase: String,
                                         verifyTime: Int64) throws -> ExplicitVerifyMessage {
        let newKey = try throwing { error in CryptoNewKeyFromArmored(armorKey, &error) }

        guard let key = newKey else {
            throw CryptoError.couldNotCreateKey
        }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key.unlock(passSlice)

        let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        // FIXME - Needs to double check
        let verifierKey = try throwing { error in CryptoNewKeyFromArmored(publicKey, &error) }

        let verifierKeyRing = try throwing { error in CryptoNewKeyRing(verifierKey, &error) }

        let pgpMsg = CryptoPGPMessage(fromArmored: message)

        let verified = try throwing { error in HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error) }

        guard let verified = verified else {
            throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
        }

        return verified
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptVerify(encrytped message: String,
                              publicKey: String,
                              privateKey binKeys: [Data],
                              passphrase: String,
                              verifyTime: Int64) throws -> ExplicitVerifyMessage? {
        do {
            return try decryptVerifyNonOptional(encrypted: message,
                                                publicKey: publicKey,
                                                privateKey: binKeys,
                                                passphrase: passphrase,
                                                verifyTime: verifyTime)
        } catch CryptoError.messageCouldNotBeDecryptedWithExplicitVerification {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Decryptor")
    public func decryptVerifyNonOptional(encrypted message: String,
                                         publicKey: String,
                                         privateKey binKeys: [Data],
                                         passphrase: String,
                                         verifyTime: Int64) throws -> ExplicitVerifyMessage {
        for binKey in binKeys {
            do {
                let newKey = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

                guard let key = newKey else {
                    continue
                }

                let passSlice = passphrase.data(using: .utf8)
                let unlockedKey = try key.unlock(passSlice)

                let privateKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

                // FIXME - Needs to double check
                let verifierKey = try throwing { error in CryptoNewKeyFromArmored(publicKey, &error) }

                let verifierKeyRing = try throwing { error in CryptoNewKeyRing(verifierKey, &error) }

                let pgpMsg = CryptoPGPMessage(fromArmored: message)

                let verified = try throwing { error in HelperDecryptExplicitVerify(pgpMsg, privateKeyRing, verifierKeyRing, verifyTime, &error) }

                guard let verified = verified else {
                    throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
                }

                return verified
            } catch {
                continue
            }
        }
        throw CryptoError.messageCouldNotBeDecryptedWithExplicitVerification
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainText: String, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
        do {
            return try encrypt(input: .left(plainText), privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainData: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
        do {
            return try encrypt(input: .right(plainData), privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainText: String, privateKey signerPrivateKey: String, passphrase: String) throws -> String {
        try encrypt(input: .left(plainText), privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainData: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String {
        try encrypt(input: .right(plainData), privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    private func encrypt(input: Either<String, Data>, privateKey signerPrivateKey: String, passphrase: String) throws -> String {
        let privateKey = try throwing { error in CryptoNewKeyFromArmored(signerPrivateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try privateKey?.unlock(passSlice)

        let publicKeyData = try unlockedKey?.getPublicKey()
        let publicKey = try throwing { error in CryptoNewKey(publicKeyData, &error) }
        let publicKeyRing = try throwing { error in CryptoNewKeyRing(publicKey, &error) }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoNewPlainMessage(plainData)
        }

        plainMessage?.textType = true
        let signerKeyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
        let armoredMessage = try throwing { error in cryptedMessage?.getArmored(&error) }

        guard let armoredMessage = armoredMessage else {
            throw CryptoError.messageCouldNotBeEncrypted
        }

        return armoredMessage
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainText: String, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String? {
        do {
            return try encrypt(input: .left(plainText), publicKey: publicKey, privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainData: Data, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String? {
        do {
            return try encrypt(input: .right(plainData), publicKey: publicKey, privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }
    
    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainText: String, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String {
        try encrypt(input: .left(plainText), publicKey: publicKey, privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainData: Data, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String {
        try encrypt(input: .right(plainData), publicKey: publicKey, privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    private func encrypt(input: Either<String, Data>, publicKey: String, privateKey signerPrivateKey: String = "", passphrase: String = "") throws -> String {
        let newKey = try throwing { error in CryptoNewKeyFromArmored(publicKey, &error) }

        guard let key = newKey else {
            throw CryptoError.couldNotCreateKey
        }

        let publicKeyRing = try throwing { error in CryptoNewKeyRing(key, &error) }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoNewPlainMessage(plainData)
        }

        var signerKeyRing: KeyRing?
        if !signerPrivateKey.isEmpty {
            let signerKey = try throwing { error in CryptoNewKeyFromArmored(signerPrivateKey, &error) }

            let passSlice = passphrase.data(using: .utf8)
            let unlockedSignerKey = try signerKey?.unlock(passSlice)

            signerKeyRing = try throwing { error in CryptoNewKeyRing(unlockedSignerKey, &error) }
        }

        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
        let armoredMessage = try throwing { error in cryptedMessage?.getArmored(&error) }
        guard let armoredMessage = armoredMessage else {
            throw CryptoError.messageCouldNotBeEncrypted
        }

        return armoredMessage
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainText: String, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
        do {
            return try encrypt(input: .left(plainText), publicKey: binKey, privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainData: Data, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String? {
        do {
            return try encrypt(input: .right(plainData), publicKey: binKey, privateKey: signerPrivateKey, passphrase: passphrase)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }
    
    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainText: String, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String {
        try encrypt(input: .left(plainText), publicKey: binKey, privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainData: Data, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String {
        try encrypt(input: .right(plainData), publicKey: binKey, privateKey: signerPrivateKey, passphrase: passphrase)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    private func encrypt(input: Either<String, Data>, publicKey binKey: Data, privateKey signerPrivateKey: String, passphrase: String) throws -> String {

        let newKey = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

        guard let key = newKey else {
            throw CryptoError.couldNotCreateKey
        }

        let publicKeyRing = try throwing { error in CryptoNewKeyRing(key, &error) }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoNewPlainMessage(plainData)
        }

        var signerKeyRing: KeyRing?
        if !signerPrivateKey.isEmpty {
            let signerKey = try throwing { error in CryptoNewKeyFromArmored(signerPrivateKey, &error) }

            let passSlice = passphrase.data(using: .utf8)
            let unlockedSignerKey = try signerKey?.unlock(passSlice)

            signerKeyRing = try throwing { error in CryptoNewKeyRing(unlockedSignerKey, &error) }
        }

        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: signerKeyRing)
        let armoredMessage = try throwing { error in cryptedMessage?.getArmored(&error) }

        guard let armoredMessage = armoredMessage else {
            throw CryptoError.messageCouldNotBeEncrypted
        }

        return armoredMessage
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainText: String, publicKey binKey: Data) throws -> String? {
        do {
            return try encrypt(input: .left(plainText), publicKey: binKey)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainData: Data, publicKey binKey: Data) throws -> String? {
        do {
            return try encrypt(input: .right(plainData), publicKey: binKey)
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch CryptoError.couldNotCreateKey {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainText: String, publicKey binKey: Data) throws -> String {
        try encrypt(input: .left(plainText), publicKey: binKey)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainData: Data, publicKey binKey: Data) throws -> String {
        try encrypt(input: .right(plainData), publicKey: binKey)
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    private func encrypt(input: Either<String, Data>, publicKey binKey: Data) throws -> String {

        let newKey = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

        guard let key = newKey else {
            throw CryptoError.couldNotCreateKey
        }

        let publicKeyRing = try throwing { error in CryptoNewKeyRing(key, &error) }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoNewPlainMessage(plainData)
        }

        let cryptedMessage = try publicKeyRing?.encrypt(plainMessage, privateKey: nil)
        let armoredMessage = try throwing { error in cryptedMessage?.getArmored(&error) }

        guard let armoredMessage = armoredMessage else {
            throw CryptoError.messageCouldNotBeEncrypted
        }

        return armoredMessage
    }

    // MARK: - encrypt with password

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainText: String, token: String) throws -> String? {
        do {
            return try encrypt(input: .left(plainText), token: TokenPassword.init(value: token)).value
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func encrypt(plainData: Data, token: String) throws -> String? {
        do {
            return try encrypt(input: .right(plainData), token: TokenPassword.init(value: token)).value
        } catch CryptoError.messageCouldNotBeEncrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainText: String, token: String) throws -> String {
        try encrypt(input: .left(plainText), token: TokenPassword.init(value: token)).value
    }

    @available(*, deprecated, message: "Please find the replacement in Encryptor")
    public func encryptNonOptional(plainData: Data, token: String) throws -> String {
        try encrypt(input: .right(plainData), token: TokenPassword.init(value: token)).value
    }

    @available(*, deprecated, message: "Please use the variant returning non-optional")
    public func decrypt(encrypted: String, token: String) throws -> String? {
        do {
            return try decryptNonOptional(encrypted: encrypted, token: token)
        } catch CryptoError.messageCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func decryptNonOptional(encrypted: String, token: String) throws -> String {
        let tokenBytes = token.data(using: .utf8)
        let pgpMsg = try throwing { error in CryptoNewPGPMessageFromArmored(encrypted, &error) }
        let message = try throwing { error in CryptoDecryptMessageWithPassword(pgpMsg, tokenBytes, &error) }
        guard let message = message else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        return message.getString()
    }

    // MARK: - Attachment
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey: String, passphrase: String) throws -> Data? {
        do {
            return try decryptAttachmentNonOptional(keyPacket: keyPacket, dataPacket: dataPacket, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func decryptAttachmentNonOptional(keyPacket: Data, dataPacket: Data, privateKey: String, passphrase: String) throws -> Data {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)
        let keyRing = try throwing { error in  CryptoNewKeyRing(unlockedKey, &error) }

        let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
        guard let plainMessage = plainMessage, let binaryMessage = plainMessage.getBinary() else {
            throw CryptoError.attachmentCouldNotBeDecrypted
        }
        return binaryMessage
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment1(splitMessage: SplitMessage, privateKey: String, passphrase: String) throws -> Data? {
        do {
            return try decryptAttachment1NonOptional(splitMessage: splitMessage, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func decryptAttachment1NonOptional(splitMessage: SplitMessage, privateKey: String, passphrase: String) throws -> Data {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }
        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)
        let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }
        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
        guard let plainMessage = plainMessage, let binaryMessage = plainMessage.getBinary() else {
            throw CryptoError.attachmentCouldNotBeDecrypted
        }
        return binaryMessage
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(keyPacket: Data, dataPacket: Data, privateKey binKeys: [Data], passphrase: String) throws -> Data? {
        do {
            return try decryptAttachmentNonOptional(keyPacket: keyPacket, dataPacket: dataPacket, privateKey: binKeys, passphrase: passphrase)
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func decryptAttachmentNonOptional(keyPacket: Data, dataPacket: Data, privateKey binKeys: [Data], passphrase: String) throws -> Data {
        for binKey in binKeys {
            do {
                let key = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

                let passSlice = passphrase.data(using: .utf8)
                let unlockedKey = try key?.unlock(passSlice)
                let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

                let splitMessage = CryptoNewPGPSplitMessage(keyPacket.mutable as Data, dataPacket.mutable as Data)
                let plainMessage = try keyRing?.decryptAttachment(splitMessage)
                guard let plainMessage = plainMessage, let binaryMessage = plainMessage.getBinary() else {
                    throw CryptoError.attachmentCouldNotBeDecrypted
                }
                return binaryMessage
            } catch {
                continue
            }
        }
        throw CryptoError.attachmentCouldNotBeDecrypted
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(encrypted: String, privateKey: String, passphrase: String) throws -> Data? {
        do {
            return try decryptAttachmentNonOptional(encrypted: encrypted, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func decryptAttachmentNonOptional(encrypted: String, privateKey: String, passphrase: String) throws -> Data {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)
        let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let splitMessage = try throwing { error in CryptoNewPGPSplitMessageFromArmored(encrypted, &error) }

        let plainMessage = try keyRing?.decryptAttachment(splitMessage)
        guard let plainMessage = plainMessage, let binaryMessage = plainMessage.getBinary() else {
            throw CryptoError.attachmentCouldNotBeDecrypted
        }
        return binaryMessage
    }

    @available(*, deprecated, message: "Please use the non-optional variant")
    public func encryptAttachment(plainData: Data, fileName: String, publicKey: String) throws -> SplitMessage? {
        do {
            return try encryptAttachmentNonOptional(plainData: plainData, fileName: fileName, publicKey: ArmoredKey.init(value: publicKey))
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    // MARK: - sign

    @available(*, deprecated, message: "Please use non-optional variant")
    public static func signDetached(plainData: Data, privateKey: String, passphrase: String) throws -> String? {
        do {
            return try signDetachedNonOptional(plainData: plainData, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.couldNotSignDetached {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in signer")
    public static func signDetachedNonOptional(plainData: Data, privateKey: String, passphrase: String) throws -> String {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)
        let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
        let pgpSignature = try keyRing?.signDetached(plainMessage)
        let signature = try throwing { error in pgpSignature?.getArmored(&error) }

        guard let signature = signature else {
            throw CryptoError.couldNotSignDetached
        }

        return signature
    }

    @available(*, deprecated, message: "Please find the replacement in signer")
    public func signDetached(plainText: String, privateKey: String, passphrase: String) throws -> String {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)
        let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        let plainMessage = CryptoNewPlainMessageFromString(plainText)
        let pgpSignature = try keyRing!.signDetached(plainMessage)
        let signature = try throwing { error in pgpSignature.getArmored(&error) }

        return signature
    }

    @available(*, deprecated, message: "Please find the replacement in signer")
    public func verifyDetached(signature: String, plainText: String, publicKey: String, verifyTime: Int64) throws -> Bool {
        try verifyDetached(signature: signature, input: .left(plainText), publicKey: publicKey, verifyTime: verifyTime)
    }

    @available(*, deprecated, message: "Please find the replacement in signer")
    public func verifyDetached(signature: String, plainData: Data, publicKey: String, verifyTime: Int64) throws -> Bool {
        try verifyDetached(signature: signature, input: .right(plainData), publicKey: publicKey, verifyTime: verifyTime)
    }

    @available(*, deprecated, message: "Please find the replacement in signer")
    private func verifyDetached(signature: String, input: Either<String, Data>, publicKey: String, verifyTime: Int64) throws -> Bool {
        let key = try throwing { error in CryptoNewKeyFromArmored(publicKey, &error) }
        let publicKeyRing = try throwing { error in CryptoNewKeyRing(key, &error) }

        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoNewPlainMessage(plainData.mutable as Data)
        }

        let signature = try throwing { error in CryptoNewPGPSignatureFromArmored(signature, &error) }

        do {
            try publicKeyRing?.verifyDetached(plainMessage, signature: signature, verifyTime: verifyTime)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Session

    // key packet part
    @available(*, deprecated, message: "Please use non-optional variant")
    public func getSession(keyPacket: Data, privateKeys: [Data], passphrase: String) throws -> SymmetricKey? {
        do {
            return try getSessionNonOptional(keyPacket: keyPacket, privateKeys: privateKeys, passphrase: passphrase)
        } catch CryptoError.sessionKeyCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func getSessionNonOptional(keyPacket: Data, privateKeys binKeys: [Data], passphrase: String) throws -> SymmetricKey {
        for binKey in binKeys {
            do {
                let key = try throwing { error in CryptoNewKey(binKey.mutable as Data, &error) }

                let passSlice = passphrase.data(using: .utf8)
                let unlockedKey = try key?.unlock(passSlice)

                let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

                guard let sessionKey = try keyRing?.decryptSessionKey(keyPacket.mutable as Data) else {
                    throw CryptoError.sessionKeyCouldNotBeDecrypted
                }
                return sessionKey
            } catch {
                continue
            }
        }
        throw CryptoError.sessionKeyCouldNotBeDecrypted
    }

    @available(*, deprecated, message: "Please use non-optional variant")
    public func getSession(keyPacket: Data, privateKey: String, passphrase: String) throws -> SymmetricKey? {
        do {
            return try getSessionNonOptional(keyPacket: keyPacket, privateKey: privateKey, passphrase: passphrase)
        } catch CryptoError.sessionKeyCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }

    @available(*, deprecated, message: "Please find the replacement in decryptor")
    public func getSessionNonOptional(keyPacket: Data, privateKey: String, passphrase: String) throws -> SymmetricKey {
        let key = try throwing { error in CryptoNewKeyFromArmored(privateKey, &error) }

        let passSlice = passphrase.data(using: .utf8)
        let unlockedKey = try key?.unlock(passSlice)

        let keyRing = try throwing { error in CryptoNewKeyRing(unlockedKey, &error) }

        guard let sessionKey = try keyRing?.decryptSessionKey(keyPacket.mutable as Data) else {
            throw CryptoError.sessionKeyCouldNotBeDecrypted
        }
        return sessionKey
    }

    // MARK: - static

    @available(*, deprecated, message: "Please use non-optional variant")
    public func buildKeyRing(keys: [Data]) -> CryptoKeyRing? {
        do {
            return try buildKeyRingNonOptional(adding: keys)
        } catch {
            return nil
        }
    }
    
    @available(*, deprecated, message: "Please use `buildPublicKeyRing`")
    public func buildKeyRingNonOptional(adding keys: [Data]) throws -> CryptoKeyRing {
        let newKeyRing = try throwing { error in CryptoNewKeyRing(nil, &error) }
        guard let keyRing = newKeyRing else {
            throw CryptoError.couldNotCreateKeyRing
        }
        for key in keys {
            do {
                let keyToAdd = try throwing { error in CryptoNewKey(key, &error) }
                if let keyToAdd = keyToAdd {
                    try keyRing.add(keyToAdd)
                }
            } catch {
                continue
            }
        }
        return keyRing
    }

    @available(*, deprecated, message: "Please use non-optional variant")
    public func buildPrivateKeyRing(keys: [Data], passphrase: String) -> CryptoKeyRing? {
        do {
            return try buildPrivateKeyRingNonOptional(adding: keys, passphrase: passphrase)
        } catch {
            return nil
        }
    }

    @available(*, deprecated, message: "Please use `buildPrivateKeyRingUnlock`")
    public func buildPrivateKeyRingNonOptional(adding keys: [Data], passphrase: String) throws -> CryptoKeyRing {
        let newKeyRing = try throwing { error in CryptoNewKeyRing(nil, &error) }
        guard let keyRing = newKeyRing else {
            throw CryptoError.couldNotCreateKeyRing
        }
        let passSlice = passphrase.data(using: .utf8)

        for key in keys {
            do {
                let newKey = try throwing { error in CryptoNewKey(key, &error) }
                if let unlockedKey = try newKey?.unlock(passSlice) {
                    try keyRing.add(unlockedKey)
                }
            } catch {
                continue
            }
        }
        return keyRing
    }

    @available(*, deprecated, message: "Please use `buildPrivateKeyRingUnlock`")
    public func buildPrivateKeyRing(keys: [(privateKey: String, passphrase: String)]) throws -> CryptoKeyRing {
        let newKeyRing = try throwing { error in CryptoNewKeyRing(nil, &error) }

        guard let keyRing = newKeyRing else {
            throw CryptoError.couldNotCreateKeyRing
        }
        for key in keys {
            let passSlice = key.passphrase.utf8

            do {
                let lockedKey = try throwing { error in CryptoNewKeyFromArmored(key.privateKey, &error) }

                if let unlockedKey = try lockedKey?.unlock(passSlice) {
                    try keyRing.add(unlockedKey)
                }
            } catch {
                continue
            }
        }
        return keyRing
    }
}
