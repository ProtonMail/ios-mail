//
//  Crypto+Extension.swift
//  ProtonCore-Crypto - Created on 07/19/22.
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
import ProtonCoreUtilities

/// core module layer go crypto wraper
public class Crypto {
    
    private let keyRingBuilder = KeyRingBuilder()
    
    /// default init
    public init() { }
    
    /// Sets default configuration values to the Go Crypto library
    public func initializeGoCryptoWithDefaultConfiguration() {
        Crypto.setKeyGenerationOffset(-600)
    }
    
    /// update go crypto global timestamp.
    ///   - this is very important and it affects account creation and signature validation
    ///   - it is a global value in go layer
    /// - Parameter time: int64 latest server response timestamp. please use the timestamp you got from server response
    public static func updateTime( _ time: Int64) {
        CryptoGo.CryptoUpdateTime(time)
    }
    
    /// update go crypto global key gen timestamp off set
    /// - Parameter time: time offset. for example: `-10`, 10 second past. `20`, 20 second future
    public static func setKeyGenerationOffset(_ time: Int64) {
        /// The timestamp used to generate encrytion keys will be 600 seconds previous to the current timestamp.
        /// This will help avoid an issue by which sometimes keys are generated with an invalid timestamp in the future and rejected as invalid by the backend.
        CryptoGo.CryptoSetKeyGenerationOffset(time)
    }
    
    /// Golang layer interface. free memery. context is sometimes when encrypt/decrypt large files. the memery will be hold by some reasons.
    public static func freeGolangMem() {
        CryptoGo.HelperFreeOSMemory()
    }
    
    public static func random(byte: Int) throws -> Data {
        let data = try throwing { error in CryptoGo.CryptoRandomToken(byte, &error) }
        guard let randomData = data else {
            throw CryptoError.couldNotCreateRandomToken
        }
        return randomData
    }
    
    internal func encryptAndSign(plainRaw: Either<String, Data>,
                                 publicKey: ArmoredKey, signingKey: SigningKey?, signatureContext: SignatureContext?) throws -> SplitPacket {
        let armoredMessage: ArmoredMessage = try self.encryptAndSign(plainRaw: plainRaw, publicKey: publicKey, signingKey: signingKey, signatureContext: signatureContext)
        
        let splitMessage = try throwingNotNil { error in CryptoGo.CryptoNewPGPSplitMessageFromArmored(armoredMessage.value, &error) }
        
        guard let dataPacket = splitMessage.dataPacket else {
            throw CryptoError.splitMessageDataNil
        }
        
        guard let keyPacket = splitMessage.keyPacket else {
            throw CryptoError.splitMessageKeyNil
        }
        return SplitPacket.init(dataPacket: dataPacket, keyPacket: keyPacket)
    }
    
    /// Base fun to handle the encryption and signing
    /// - Parameters:
    ///   - plainRaw: plain text or plain data.
    ///   - publicKey: armored public key
    ///   - signingKey: signing key pack. include a private key and its passphase
    /// - Returns: encrypted Armored message
    internal func encryptAndSign(plainRaw: Either<String, Data>,
                                 publicKey: ArmoredKey, signingKey: SigningKey?, signatureContext: SignatureContext?) throws -> ArmoredMessage {
        
        let publicKeyRing = try self.keyRingBuilder.buildPublicKeyRing(armoredKeys: [publicKey])
        
        let plainMessage: CryptoPlainMessage?
        switch plainRaw {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }
        
        var signerKeyRing: KeyRing?
        if let signer = signingKey, !signer.isEmpty {
            let signerPrivKey: CryptoKey = try throwingNotNil { error in CryptoGo.CryptoNewKeyFromArmored(signer.privateKey.value, &error) }
            guard signerPrivKey.isPrivate() else {
                throw CryptoError.signerNotPrivateKey
            }
            let passSlice = signer.passphrase.data
            let unlockedSignerKey = try signerPrivKey.unlock(passSlice)
            signerKeyRing = try throwing { error in CryptoGo.CryptoNewKeyRing(unlockedSignerKey, &error) }
        }
        
        let context = try signatureContext?.cast()
        
        let encryptedMessage = try publicKeyRing.encrypt(withContext: plainMessage, privateKey: signerKeyRing, signingContext: context)
        let armoredMessage = try throwing { error in encryptedMessage.getArmored(&error) }
        guard !armoredMessage.isEmpty else {
            throw CryptoError.messageCouldNotBeEncrypted
        }
        return ArmoredMessage.init(value: armoredMessage)
    }
    
    public func encryptSessionKey(publicKey: ArmoredKey, sessionKey: SessionKey) throws -> Based64String {
        let keyPacket = try self.encryptSessionRaw(publicKey: publicKey, session: sessionKey.sessionKey, algo: sessionKey.algo)
        return Based64String.init(raw: keyPacket)
    }
    
    /// decrypt key packet to get decrypted SymmetricKey object
    /// - Parameters:
    ///   - decryptionKeys: decryption keys
    ///   - keyPacket: key packet
    /// - Returns: SymmetricKey
    internal func decryptSessionKey(decryptionKeys: [DecryptionKey], keyPacket: Data) throws -> SessionKey {
        
        let decryptionKeyRing = try keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        defer { decryptionKeyRing.clearPrivateParams() }
        
        let sessionKey = try decryptionKeyRing.decryptSessionKey(keyPacket)
        
        guard let algo = Algorithm.init(rawValue: sessionKey.algo) else {
            throw SessionError.unSupportedAlgorithm
        }
        
        guard let key = sessionKey.key else {
            throw SessionError.emptyKey
        }
        
        return SessionKey.init(sessionKey: key, algo: algo)
    }
    
    private func encryptSessionRaw(publicKey: ArmoredKey, session: Data, algo: Algorithm) throws -> Data {
        let symKey = CryptoGo.CryptoNewSessionKeyFromToken(session.mutable as Data, algo.value)
        let key = try throwing { error in CryptoGo.CryptoNewKeyFromArmored(publicKey.value, &error) }
        let keyRing = try throwingNotNil { error in CryptoGo.CryptoNewKeyRing(key, &error) }
        
        return try keyRing.encryptSessionKey(symKey)
    }
    
    // swiftlint:disable function_parameter_count
    internal func encryptStreamRetSha256(_ sessionKey: CryptoSessionKey,
                                         _ signKeyRing: CryptoKeyRing?,
                                         _ blockFile: FileHandle,
                                         _ ciphertextFile: FileHandle,
                                         _ totalSize: Int,
                                         _ bufferSize: Int ) throws -> Data {
        
        let ciphertextWriter = CryptoGo.HelperMobile2GoWriterWithSHA256(File.FileMobileWriter(file: ciphertextFile))!
        let plaintextWriter = try sessionKey.encryptStream(ciphertextWriter, plainMessageMetadata: nil, sign: signKeyRing)
        
        var offset = 0
        var n = 0
        while offset < totalSize {
            try autoreleasepool {
                blockFile.seek(toFileOffset: UInt64(offset))
                let currentBufferSize = offset + bufferSize > totalSize ? totalSize - offset : bufferSize
                let currentBuffer = blockFile.readData(ofLength: currentBufferSize)
                try plaintextWriter.write(currentBuffer, n: &n)
                offset += n
            }
        }
        
        try plaintextWriter.close()
        
        return ciphertextWriter.getSHA256()!
    }
    
    private func signStream(_ signKeyRing: CryptoKeyRing,
                            _ encryptKeyRing: CryptoKeyRing,
                            _ plaintextFile: FileHandle,
                            _ signatureContext: SignatureContext?
    ) throws -> ArmoredSignature {
        var error: NSError?
        let plaintextReader = CryptoGo.HelperMobile2GoReader(File.FileMobileReader(file: plaintextFile))
        let context = try signatureContext?.cast()
        let signature = try signKeyRing.signDetachedStream(withContext: plaintextReader, context: context)
        let signatureData = signature.data
        let signatureMessage = CryptoGo.CryptoNewPlainMessage(signatureData)
        let encSignature = try encryptKeyRing.encrypt(signatureMessage, privateKey: nil)
        let encSignatureArmored = encSignature.getArmored(&error)
        guard error == nil else {
            throw error!
        }
        return ArmoredSignature.init(value: encSignatureArmored)
    }
    
    internal func encryptStream(_ publicKey: ArmoredKey,
                                _ blockFile: FileHandle,
                                _ cipherTextFile: FileHandle,
                                _ totalSize: Int,
                                _ bufferSize: Int ) throws -> Data {
        
        guard let cipherTextWriter = CryptoGo.HelperMobile2GoWriter(File.FileMobileWriter(file: cipherTextFile)) else {
            throw CryptoError.couldNotCreateKey // EncryptError.unableToMakeWriter
        }
        
        let keyRing = try self.keyRingBuilder.buildPublicKeyRing(armoredKeys: [publicKey])
        
        let plaintextWriter = try keyRing.encryptSplitStream(cipherTextWriter,
                                                             plainMessageMetadata: nil,
                                                             sign: nil)
        var offset = 0
        var index = 0
        while offset < totalSize {
            try autoreleasepool {
                blockFile.seek(toFileOffset: UInt64(offset))
                let currentBufferSize = offset + bufferSize > totalSize ? totalSize - offset : bufferSize
                let currentBuffer = blockFile.readData(ofLength: currentBufferSize)
                try plaintextWriter.write(currentBuffer, n: &index)
                offset += index
            }
        }
        
        try plaintextWriter.close()
        
        return try plaintextWriter.getKeyPacket()
    }
    
    internal func decryptAndVerify(decryptionKeys: [DecryptionKey],
                                   split: SplitPacket,
                                   verifications: [ArmoredKey],
                                   verifyTime: Int64,
                                   verificationContext: VerificationContext?) throws -> VerifiedString {
        let verifyMessage: VerifiedMessage<CryptoPlainMessage> = try decryptAndVerify(
            decryptionKeys: decryptionKeys,
            encrypted: .right(split),
            verifications: verifications,
            verifyTime: verifyTime,
            verificationContext: verificationContext
        )

        return verifyMessage.map { $0.getString() }
    }
    
    internal func decryptAndVerify(decryptionKeys: [DecryptionKey],
                                   split: SplitPacket,
                                   verifications: [ArmoredKey],
                                   verifyTime: Int64,
                                   verificationContext: VerificationContext?) throws -> VerifiedData {
        let verifyMessage: VerifiedMessage<CryptoPlainMessage> = try decryptAndVerify(
            decryptionKeys: decryptionKeys,
            encrypted: .right(split),
            verifications: verifications,
            verifyTime: verifyTime,
            verificationContext: verificationContext
        )
        return try verifyMessage.map {
            guard let data = $0.data else {
                throw CryptoError.emptyResult
            }
            return data
        }
    }
    
    internal func decryptAndVerify(decryptionKeys: [DecryptionKey],
                                   encrypted: ArmoredMessage,
                                   verifications: [ArmoredKey],
                                   verifyTime: Int64,
                                   verificationContext: VerificationContext?) throws -> VerifiedData {
        let verifyMessage: VerifiedMessage<CryptoPlainMessage> = try decryptAndVerify(
            decryptionKeys: decryptionKeys,
            encrypted: .left(encrypted),
            verifications: verifications,
            verifyTime: verifyTime,
            verificationContext: verificationContext
        )
        return try verifyMessage.map {
            guard let data = $0.data else {
                throw CryptoError.emptyResult
            }
            return data
        }
    }

    internal func decryptAndVerify(decryptionKeys: [DecryptionKey],
                                   encrypted: ArmoredMessage,
                                   verifications: [ArmoredKey],
                                   verifyTime: Int64,
                                   verificationContext: VerificationContext?) throws -> VerifiedString {
        let verifyMessage: VerifiedMessage<CryptoPlainMessage> = try decryptAndVerify(
            decryptionKeys: decryptionKeys,
            encrypted: .left(encrypted),
            verifications: verifications,
            verifyTime: verifyTime,
            verificationContext: verificationContext
        )
        return verifyMessage.map { $0.getString() }
    }

    private func decryptAndVerify(
        decryptionKeys: [DecryptionKey],
        encrypted: Either<ArmoredMessage, SplitPacket>,
        verifications: [ArmoredKey],
        verifyTime: Int64,
        verificationContext: VerificationContext?
    ) throws -> VerifiedMessage<CryptoPlainMessage> {
        let pgpMsg: CryptoPGPMessage = try throwingNotNil { _ in
            switch encrypted {
            case .left(let armoredMessage):
                return CryptoGo.CryptoPGPMessage(fromArmored: armoredMessage.value)
            case .right(let split):
                return CryptoGo.CryptoPGPSplitMessage(split.keyPacket, dataPacket: split.dataPacket)?.getPGPMessage()
            }
        }

        let verifyMessage: ExplicitVerifyMessage = try self.decryptAndVerify(decryptionKeys: decryptionKeys,
                                                                             encrypted: pgpMsg,
                                                                             verifications: verifications,
                                                                             verifyTime: verifyTime,
                                                                             verificationContext: verificationContext)
        guard let message = verifyMessage.messageGoCrypto else {
            throw CryptoError.emptyResult
        }

        if let rawSignatureVerificationError = verifyMessage.signatureVerificationErrorGoCrypto {
            let signatureVerificationError = SignatureVerifyError(
                code: rawSignatureVerificationError.status,
                message: rawSignatureVerificationError.message
            )
            return .unverified(message, signatureVerificationError)
        } else {
            return .verified(message)
        }
    }
    
    func decryptAndVerify(decryptionKey: DecryptionKey, encrypted: ArmoredMessage,
                          signature: ArmoredSignature, verificationKeys: [ArmoredKey], verifyTime: Int64, trimTrailingSpaces: Bool = true, verificationContext: VerificationContext?) throws -> VerifiedString {
        
        let decryptionKeyRing = try keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: [decryptionKey])
        defer { decryptionKeyRing.clearPrivateParams() }
        
        let pgpMsg = try throwingNotNil { error in
            CryptoGo.CryptoPGPMessage(fromArmored: encrypted.value)
        }
        
        let decrypted = try decryptionKeyRing.decrypt(pgpMsg, verifyKey: nil, verifyTime: 0).getString()
        
        let verificationKeyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: verificationKeys)
        
        let context = try verificationContext?.cast()
        
        let signature = CryptoGo.CryptoPGPSignature(fromArmored: signature.value)
        
        let verifyUnixTime = verifyTime == 0 ? CryptoGo.CryptoGetUnixTime() : verifyTime
        do {
            let trimmed = (trimTrailingSpaces) ? decrypted.trimTrailingSpaces() : decrypted
            let plainMessage = CryptoGo.CryptoPlainMessage(from: trimmed)
            try verificationKeyRing.verifyDetached(withContext: plainMessage, signature: signature, verifyTime: verifyUnixTime, verificationContext: context)
            return .verified(decrypted)
        } catch {
            return .unverified(decrypted, error)
        }
    }
    
    func decryptAndVerify(decryptionKey: DecryptionKey, keyPacket: Data,
                          signature: ArmoredSignature, verificationKeys: [ArmoredKey], verifyTime: Int64, verificationContext: VerificationContext?) throws -> VerifiedData {
        
        let decryptionKeyRing = try keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: [decryptionKey])
        defer { decryptionKeyRing.clearPrivateParams() }
        
        guard let sessionKey = try decryptionKeyRing.decryptSessionKey(keyPacket.mutable as Data).key else {
            throw CryptoError.sessionKeyCouldNotBeDecrypted
        }
        
        let verificationKeyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: verificationKeys)
        
        let signature = CryptoGo.CryptoPGPSignature(fromArmored: signature.value)
        
        let context = try verificationContext?.cast()
        
        do {
            let plainMessage = CryptoGo.CryptoPlainMessage(sessionKey)
            try verificationKeyRing.verifyDetached(withContext: plainMessage, signature: signature, verifyTime: CryptoGo.CryptoGetUnixTime(), verificationContext: context)
            return .verified(sessionKey)
        } catch { }
        
        do {
            let plainMessage = CryptoGo.CryptoPlainMessage(keyPacket)
            try verificationKeyRing.verifyDetached(withContext: plainMessage, signature: signature, verifyTime: CryptoGo.CryptoGetUnixTime(), verificationContext: context)
            return .verified(sessionKey)
        } catch {
            return .unverified(sessionKey, error)
        }
    }
    
    private func decryptAndVerify(decryptionKeys: [DecryptionKey],
                                  encrypted: PGPMessage,
                                  verifications: [ArmoredKey],
                                  verifyTime: Int64,
                                  verificationContext: VerificationContext?) throws -> ExplicitVerifyMessage {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let verifierKeyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: verifications)
        
        let context = try verificationContext?.cast()
        
        let verified = try throwingNotNil { error in
            CryptoGo.HelperDecryptExplicitVerifyWithContext(encrypted, privateKeyRing, verifierKeyRing, verifyTime, context, &error)
        }
        return verified
    }
    
    internal func decrypt(decryptionKeys: [DecryptionKey], encrypted: ArmoredMessage) throws -> String {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let pgpMsg = try throwingNotNil { error in
            CryptoGo.CryptoPGPMessage(fromArmored: encrypted.value)
        }
        
        let plainMessageString = try privateKeyRing.decrypt(pgpMsg, verifyKey: nil,
                                                            verifyTime: CryptoGo.CryptoGetUnixTime())
        
        return plainMessageString.getString()
    }
    
    internal func decrypt(decryptionKeys: [DecryptionKey], encrypted: ArmoredMessage) throws -> Data {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let pgpMsg = try throwingNotNil { error in
            CryptoGo.CryptoPGPMessage(fromArmored: encrypted.value)
        }
        
        let plainMessageString = try privateKeyRing.decrypt(pgpMsg, verifyKey: nil,
                                                            verifyTime: CryptoGo.CryptoGetUnixTime())
        
        guard let data = plainMessageString.data else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        
        return data
    }
    
    internal func decrypt(decryptionKeys: [DecryptionKey], split: SplitPacket) throws -> Data {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let splitMsg = try throwingNotNil { error in
            CryptoGo.CryptoPGPSplitMessage(split.keyPacket, dataPacket: split.dataPacket)
        }
        
        let pgpMsg = try throwingNotNil { error in
            splitMsg.getPGPMessage()
        }
        
        let plainMessageString = try privateKeyRing.decrypt(pgpMsg, verifyKey: nil,
                                                            verifyTime: CryptoGo.CryptoGetUnixTime())
        
        guard let data = plainMessageString.data else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        
        return data
    }
    
    private func decrypt(decryptionKeys: [DecryptionKey],
                         encrypted: PGPMessage,
                         verifyTime: Int64) throws -> String {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let plainMessageString = try privateKeyRing.decrypt(encrypted, verifyKey: nil,
                                                            verifyTime: CryptoGo.CryptoGetUnixTime())
        
        return plainMessageString.getString()
    }
    
    private func decrypt(decryptionKeys: [DecryptionKey],
                         encrypted: PGPMessage,
                         verifyTime: Int64) throws -> Data {
        
        let privateKeyRing = try self.keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        
        let plainMessageString = try privateKeyRing.decrypt(encrypted, verifyKey: nil,
                                                            verifyTime: CryptoGo.CryptoGetUnixTime())
        
        guard let data = plainMessageString.data else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        
        return data
    }
    
    // swiftlint:disable function_parameter_count
    internal func decryptStream(encryptedFile cyphertextUrl: URL,
                                decryptedFile cleartextUrl: URL,
                                decryptionKeys: [DecryptionKey],
                                keyPacket: Data,
                                verificationKeys: [ArmoredKey],
                                encryptedSignature: ArmoredMessage,
                                chunckSize: Int,
                                removeClearTextFileIfAlreadyExists: Bool = false,
                                verificationContext: VerificationContext?) throws
    {
        // prepare files
        if FileManager.default.fileExists(atPath: cleartextUrl.path) {
            if removeClearTextFileIfAlreadyExists {
                try FileManager.default.removeItem(at: cleartextUrl)
            } else {
                throw CryptoError.outputFileAlreadyExists
            }
        }
        FileManager.default.createFile(atPath: cleartextUrl.path, contents: Data(), attributes: nil)
        
        let readFileHandle = try FileHandle(forReadingFrom: cyphertextUrl)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cleartextUrl)
        defer { writeFileHandle.closeFile() }
        // cryptography
        
        let decryptionKeyRing = try keyRingBuilder.buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)
        defer { decryptionKeyRing.clearPrivateParams() }
        let sessionKey = try decryptionKeyRing.decryptSessionKey(keyPacket)
        
        try self.decryptBinaryStream(sessionKey, nil, readFileHandle, writeFileHandle, chunckSize)
        
        let verifyFileHandle = try FileHandle(forReadingFrom: cleartextUrl)
        defer { verifyFileHandle.closeFile() }
        let verificationKeyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: verificationKeys)
        
        try self.verifyStream(verificationKeyRing, decryptionKeyRing, verifyFileHandle, encryptedSignature, verificationContext)
    }
    
    internal func verifyStream(_ verifyKeyRing: CryptoKeyRing,
                               _ decryptKeyRing: CryptoKeyRing,
                               _ plaintextFile: FileHandle,
                               _ encSignatureArmored: ArmoredMessage,
                               _ verificationContext: VerificationContext?) throws
    {
        let plaintextReader = CryptoGo.HelperMobile2GoReader(File.FileMobileReader(file: plaintextFile))
        
        let encSignature = CryptoGo.CryptoPGPMessage(fromArmored: encSignatureArmored.value)
        
        let decryptedSignature = try decryptKeyRing.decrypt(encSignature, verifyKey: nil, verifyTime: 0)
        
        let context = try verificationContext?.cast()
        
        let signatureData = decryptedSignature.data
        
        try verifyKeyRing.verifyDetachedStream(
            withContext: plaintextReader,
            signature: CryptoGo.CryptoNewPGPSignature(signatureData),
            verifyTime: CryptoGo.CryptoGetUnixTime(),
            verificationContext: context
        )
    }
    
    internal func decryptBinaryStream(_ sessionKey: CryptoSessionKey,
                                      _ verifyKeyRing: CryptoKeyRing?,
                                      _ ciphertextFile: FileHandle,
                                      _ blockFile: FileHandle,
                                      _ bufferSize: Int) throws
    {
        
        let ciphertextReader = CryptoGo.HelperMobile2GoReader(File.FileMobileReader(file: ciphertextFile))
        
        let plaintextMessageReader = try sessionKey.decryptStream(
            ciphertextReader,
            verifyKeyRing: verifyKeyRing,
            verifyTime: CryptoGo.CryptoGetUnixTime()
        )
        
        let reader = CryptoGo.HelperGo2IOSReader(plaintextMessageReader)!
        var isEOF: Bool = false
        while !isEOF {
            try autoreleasepool {
                let result = try reader.read(bufferSize)
                blockFile.write(result.data ?? Data())
                isEOF = result.isEOF
            }
        }
        
        if verifyKeyRing != nil {
            try plaintextMessageReader.verifySignature()
        }
    }
    
    internal func signDetached(plainRaw: Either<String, Data>, signer: SigningKey, trimTrailingSpaces: Bool, signatureContext: SignatureContext?) throws -> ArmoredSignature {
        guard !signer.isEmpty else {
            throw SignError.invalidSigningKey
        }
        
        let key = try throwingNotNil { error in CryptoGo.CryptoNewKeyFromArmored(signer.privateKey.value, &error) }
        
        let passSlice = signer.passphrase.data
        
        let unlockedKey = try key.unlock(passSlice)
        
        let keyRing = try throwingNotNil { error in CryptoGo.CryptoNewKeyRing(unlockedKey, &error) }
        
        let plainMessage: CryptoPlainMessage?
        switch plainRaw {
        case .left(let plainText):
            let trimmed = (trimTrailingSpaces) ? plainText.trimTrailingSpaces() : plainText
            plainMessage = CryptoGo.CryptoNewPlainMessageFromString(trimmed)
        case .right(let plainData):
            plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }
        
        let context = try signatureContext?.cast()
        
        let pgpSignature = try keyRing.signDetached(withContext: plainMessage, context: context)
        
        let signature = try throwingNotNil { error in pgpSignature.getArmored(&error) }
        
        return ArmoredSignature.init(value: signature)
    }
    
    internal func verifyDetached(input: Either<String, Data>, signature: Either<ArmoredSignature, UnArmoredSignature>,
                                 verifier: ArmoredKey, verifyTime: Int64, trimTrailingSpaces: Bool, verificationContext: VerificationContext?) throws -> Bool {
        return try self.verifyDetached(input: input, signature: signature,
                                       verifiers: [verifier], verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces, verificationContext: verificationContext)
    }
    
    internal func verifyDetached(input: Either<String, Data>, signature: Either<ArmoredSignature, UnArmoredSignature>,
                                 verifiers: [ArmoredKey], verifyTime: Int64, trimTrailingSpaces: Bool, verificationContext: VerificationContext?) throws -> Bool {
        
        let publicKeyRing = try self.keyRingBuilder.buildPublicKeyRing(armoredKeys: verifiers)
        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText):
            let trimmed = (trimTrailingSpaces) ? plainText.trimTrailingSpaces() : plainText
            plainMessage = CryptoGo.CryptoNewPlainMessageFromString(trimmed)
        case .right(let plainData):
            plainMessage = CryptoGo.CryptoNewPlainMessage(plainData.mutable as Data)
        }
        let pgpSignature: CryptoPGPSignature?
        switch signature {
        case .left(let armoredSignature): pgpSignature = try throwingNotNil { error in CryptoGo.CryptoNewPGPSignatureFromArmored(armoredSignature.value, &error) }
        case .right(let plainData): pgpSignature = try throwingNotNil { error in CryptoGo.CryptoNewPGPSignature(plainData.value) }
        }
        let context = try verificationContext?.cast()
        do {
            try publicKeyRing.verifyDetached(withContext: plainMessage, signature: pgpSignature, verifyTime: verifyTime, verificationContext: context)
            return true
        } catch {
            return false
        }
    }
    
    public func signStream(publicKey: ArmoredKey, signerKey: SigningKey, plainFile: URL, signatureContext: SignatureContext?) throws -> ArmoredSignature  {
        guard !signerKey.isEmpty else {
            throw SignError.invalidSigningKey
        }
        
        guard var encryptionKey = CryptoGo.CryptoKey(fromArmored: publicKey.value) else {
            throw SignError.invalidPublicKey
        }
        
        if encryptionKey.isPrivate() {
            encryptionKey = try encryptionKey.toPublic()
        }
        
        guard let encryptionKeyRing = CryptoGo.CryptoKeyRing(encryptionKey) else {
            throw SignError.invalidPublicKey
        }
        
        guard let signKeyLocked = CryptoGo.CryptoKey(fromArmored: signerKey.privateKey.value) else {
            throw SignError.invalidPrivateKey
        }
        
        let signKeyUnlocked = try signKeyLocked.unlock(signerKey.passphrase.data)
        
        guard let signKeyRing = CryptoGo.CryptoKeyRing(signKeyUnlocked) else {
            throw SignError.invalidPrivateKey
        }
        
        let readFileHandle = try FileHandle(forReadingFrom: plainFile)
        let hash = try signStream(signKeyRing, encryptionKeyRing, readFileHandle, signatureContext)
        
        if #available(macOSApplicationExtension 10.15, macOS 15.0, *) {
            try readFileHandle.close()
        }
        
        return hash
    }
  
    internal func encrypt(input: Either<String, Data>, token: TokenPassword) throws -> ArmoredMessage {
        let plainMessage: CryptoPlainMessage?
        switch input {
        case .left(let plainText): plainMessage = CryptoGo.CryptoNewPlainMessageFromString(plainText)
        case .right(let plainData): plainMessage = CryptoGo.CryptoNewPlainMessage(plainData)
        }
        let tokenBytes = token.data
        let encryptedMessage = try throwing { error in CryptoGo.CryptoEncryptMessageWithPassword(plainMessage, tokenBytes, &error) }

        let armoredMessage = try throwing { error in encryptedMessage?.getArmored(&error) }

        guard let armoredMessage = armoredMessage else {
            throw CryptoError.messageCouldNotBeEncrypted
        }
        return ArmoredMessage.init(value: armoredMessage)
    }
    
    internal func decrypt(encrypted: ArmoredMessage, token: TokenPassword) throws -> String {
        let tokenBytes = token.data
        let pgpMsg = try throwing { error in CryptoGo.CryptoNewPGPMessageFromArmored(encrypted.value, &error) }
        let message = try throwing { error in CryptoGo.CryptoDecryptMessageWithPassword(pgpMsg, tokenBytes, &error) }
        guard let message = message else {
            throw CryptoError.messageCouldNotBeDecrypted
        }
        return message.getString()
    }
    
    public func encryptAttachmentLowMemory(fileName: String, totalSize: Int, publicKey: ArmoredKey) throws -> AttachmentProcessor {
        let keyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: [publicKey])
        let processor = try keyRing.newLowMemoryAttachmentProcessor(totalSize, filename: fileName)
        return processor
    }
    
    public func encryptAttachmentNonOptional(plainData: Data, fileName: String, publicKey: ArmoredKey) throws -> SplitMessage {
        let keyRing = try keyRingBuilder.buildPublicKeyRing(armoredKeys: [publicKey])
        // without mutable
        let splitMessage = try throwing { error in CryptoGo.HelperEncryptAttachment(plainData, fileName, keyRing, &error) }
        guard let splitMessage = splitMessage else {
            throw CryptoError.attachmentCouldNotBeEncrypted
        }
        return splitMessage
    }

    public static func updatePassphrase(privateKey: ArmoredKey, oldPassphrase: Passphrase, newPassphrase: Passphrase) throws -> ArmoredKey {
        let newKey = try throwing { error in CryptoGo.HelperUpdatePrivateKeyPassphrase(privateKey.value, oldPassphrase.data, newPassphrase.data, &error) }
        return ArmoredKey.init(value: newKey)
    }

}

internal extension SignatureContext {
    func cast() throws -> CryptoSigningContext {
        let context = CryptoGo.CryptoSigningContext(self.value, isCritical: self.isCritical)
        if let context {
            return context
        } else {
            throw CryptoError.signatureContextNotInitialised
        }
    }
}

internal extension VerificationContext {
    func cast() throws -> CryptoVerificationContext {
        let context: CryptoVerificationContext?
        switch self.required {
        case .never:
            context = CryptoGo.CryptoVerificationContext(self.value, isRequired: false, requiredAfter: 0)
        case .always:
            context = CryptoGo.CryptoVerificationContext(self.value, isRequired: true, requiredAfter: 0)
        case .after(let unixTime):
            context = CryptoGo.CryptoVerificationContext(self.value, isRequired: true, requiredAfter: unixTime)
        }
        if let context {
            return context
        } else {
            throw CryptoError.verificationContextNotInitialised
        }
    }
}
