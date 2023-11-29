//
//  CryptoGoClasses.swift
//  ProtonCore-CryptoGoImplementation - Created on 24/05/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import GoLibs
import ProtonCoreCryptoGoInterface

private func forceCast<CryptoGoType, GoLibsType>(object: CryptoGoType, to _: GoLibsType.Type) -> GoLibsType {
    assert(GoLibsType.self is CryptoGoType.Type,
           """
           Programmer's error: \(GoLibsType.self) is expected to conform to \(CryptoGoType.self).
           Have you forget to provide the protocol conformance?
           """)
    return object as! GoLibsType
}

// MARK: - CryptoKey

extension ProtonCoreCryptoGoInterface.CryptoKey {
    var toGoLibsType: GoLibs.CryptoKey {
        forceCast(object: self, to: GoLibs.CryptoKey.self)
    }
}

extension GoLibs.CryptoKey: ProtonCoreCryptoGoInterface.CryptoKey {
    public func copy(_ error: NSErrorPointer) -> ProtonCoreCryptoGoInterface.CryptoKey? {
        let value: GoLibs.CryptoKey? = copy(error)
        return value
    }

    public func lock(_ passphrase: Data?) throws -> ProtonCoreCryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try lock(passphrase)
        return value
    }

    public func toPublic() throws -> ProtonCoreCryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try toPublic()
        return value
    }

    public func unlock(_ passphrase: Data?) throws -> ProtonCoreCryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try unlock(passphrase)
        return value
    }
}

// MARK: - CryptoSessionKey

extension ProtonCoreCryptoGoInterface.CryptoSessionKey {
    var toGoLibsType: GoLibs.CryptoSessionKey {
        forceCast(object: self, to: GoLibs.CryptoSessionKey.self)
    }
}

extension GoLibs.CryptoSessionKey: ProtonCoreCryptoGoInterface.CryptoSessionKey {

    public func decryptStream(_ dataPacketReader: ProtonCoreCryptoGoInterface.CryptoReaderProtocol?, verifyKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCoreCryptoGoInterface.CryptoPlainMessageReader {
        let value: GoLibs.CryptoPlainMessageReader = try decryptStream(
            dataPacketReader?.toGoLibsType,
            verifyKeyRing: verifyKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
        return value
    }

    public func encryptStream(_ dataPacketWriter: ProtonCoreCryptoGoInterface.CryptoWriterProtocol?, plainMessageMetadata: ProtonCoreCryptoGoInterface.CryptoPlainMessageMetadata?, sign signKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
        let value: GoLibs.CryptoWriteCloserProtocol = try encryptStream(
            dataPacketWriter?.toGoLibsType,
            plainMessageMetadata: plainMessageMetadata?.toGoLibsType,
            sign: signKeyRing?.toGoLibsType
        )
        return value.toCryptoGoType
    }

    public func decrypt(_ dataPacket: Data?) throws -> ProtonCoreCryptoGoInterface.CryptoPlainMessage {
        let value: GoLibs.CryptoPlainMessage = try decrypt(dataPacket)
        return value
    }

    public func decryptAndVerify(_ dataPacket: Data?, verifyKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCoreCryptoGoInterface.CryptoPlainMessage {
        let value: GoLibs.CryptoPlainMessage = try decryptAndVerify(
            dataPacket,
            verifyKeyRing: verifyKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
        return value
    }

    public func encrypt(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?) throws -> Data {
        try encrypt(message?.toGoLibsType)
    }

    public func encryptAndSign(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, sign signKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> Data {
        try encryptAndSign(message?.toGoLibsType, sign: signKeyRing?.toGoLibsType)
    }

    public func encrypt(withCompression message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?) throws -> Data {
        try encrypt(withCompression: message?.toGoLibsType)
    }
}

// MARK: - CryptoKeyRing

extension ProtonCoreCryptoGoInterface.CryptoKeyRing {
    var toGoLibsType: GoLibs.CryptoKeyRing {
        forceCast(object: self, to: GoLibs.CryptoKeyRing.self)
    }
}



extension GoLibs.CryptoKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing {
    public func decryptMIMEMessage(_ message: ProtonCoreCryptoGoInterface.CryptoPGPMessage?, verifyKey: ProtonCoreCryptoGoInterface.CryptoKeyRing?, callbacks: ProtonCoreCryptoGoInterface.CryptoMIMECallbacksProtocol?, verifyTime: Int64) {
        decryptMIMEMessage(
            message?.toGoLibsType,
            verifyKey: verifyKey?.toGoLibsType,
            callbacks: callbacks?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func getKey(_ n: Int) throws -> ProtonCoreCryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try getKey(n)
        return value
    }

    public func signDetachedEncryptedStream(_ message: ProtonCoreCryptoGoInterface.CryptoReaderProtocol?, encryptionKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try signDetachedEncryptedStream(
            message?.toGoLibsType,
            encryptionKeyRing: encryptionKeyRing?.toGoLibsType
        )
        return value
    }

    public func verifyDetachedEncrypted(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, encryptedSignature: ProtonCoreCryptoGoInterface.CryptoPGPMessage?, decryptionKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws {
        try verifyDetachedEncrypted(
            message?.toGoLibsType,
            encryptedSignature: encryptedSignature?.toGoLibsType,
            decryptionKeyRing: decryptionKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func verifyDetachedEncryptedStream(_ message: ProtonCoreCryptoGoInterface.CryptoReaderProtocol?, encryptedSignature: ProtonCoreCryptoGoInterface.CryptoPGPMessage?, decryptionKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws {
        try verifyDetachedEncryptedStream(
            message?.toGoLibsType,
            encryptedSignature: encryptedSignature?.toGoLibsType,
            decryptionKeyRing: decryptionKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func encryptSplitStream(_ dataPacketWriter: ProtonCoreCryptoGoInterface.CryptoWriterProtocol?, plainMessageMetadata: ProtonCoreCryptoGoInterface.CryptoPlainMessageMetadata?, sign signKeyRing: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> ProtonCoreCryptoGoInterface.CryptoEncryptSplitResult {
        let value: GoLibs.CryptoEncryptSplitResult = try encryptSplitStream(
            dataPacketWriter?.toGoLibsType,
            plainMessageMetadata: plainMessageMetadata?.toGoLibsType,
            sign: signKeyRing?.toGoLibsType
        )
        return value
    }

    public func encrypt(withContext message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, privateKey: ProtonCoreCryptoGoInterface.CryptoKeyRing?, signingContext: ProtonCoreCryptoGoInterface.CryptoSigningContext?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try encrypt(
            withContext: message?.toGoLibsType,
            privateKey: privateKey?.toGoLibsType,
            signingContext: signingContext?.toGoLibsType
        )
        return value
    }

    public func newLowMemoryAttachmentProcessor(_ estimatedSize: Int, filename: String?) throws -> ProtonCoreCryptoGoInterface.CryptoAttachmentProcessor {
        let value: GoLibs.CryptoAttachmentProcessor = try newLowMemoryAttachmentProcessor(estimatedSize, filename: filename)
        return value
    }

    public func signDetachedStream(withContext message: ProtonCoreCryptoGoInterface.CryptoReaderProtocol?, context: ProtonCoreCryptoGoInterface.CryptoSigningContext?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetachedStream(
            withContext: message?.toGoLibsType,
            context: context?.toGoLibsType
        )
        return value
    }

    public func signDetached(withContext message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, context: ProtonCoreCryptoGoInterface.CryptoSigningContext?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetached(
            withContext: message?.toGoLibsType,
            context: context?.toGoLibsType
        )
        return value
    }

    public func verifyDetachedStream(withContext message: ProtonCoreCryptoGoInterface.CryptoReaderProtocol?, signature: ProtonCoreCryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64, verificationContext: ProtonCoreCryptoGoInterface.CryptoVerificationContext?) throws {
        try verifyDetachedStream(
            withContext: message?.toGoLibsType,
            signature: signature?.toGoLibsType,
            verifyTime: verifyTime,
            verificationContext: verificationContext?.toGoLibsType
        )
    }

    public func verifyDetached(withContext message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, signature: ProtonCoreCryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64, verificationContext: ProtonCoreCryptoGoInterface.CryptoVerificationContext?) throws {
        try verifyDetached(
            withContext: message?.toGoLibsType,
            signature: signature?.toGoLibsType,
            verifyTime: verifyTime,
            verificationContext: verificationContext?.toGoLibsType
        )
    }


    public func decryptSessionKey(_ keyPacket: Data?) throws -> ProtonCoreCryptoGoInterface.CryptoSessionKey {
        let value: GoLibs.CryptoSessionKey = try decryptSessionKey(keyPacket)
        return value
    }

    public func encrypt(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, privateKey: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try encrypt(message?.toGoLibsType,
                                                         privateKey: privateKey?.toGoLibsType)
        return value
    }
    
    public func encrypt(withCompression message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, privateKey: ProtonCoreCryptoGoInterface.CryptoKeyRing?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try encrypt(withCompression: message?.toGoLibsType,
                                                         privateKey: privateKey?.toGoLibsType)
        return value
    }

    public func signDetached(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?) throws -> ProtonCoreCryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetached(message?.toGoLibsType)
        return value
    }

    public func verifyDetached(_ message: ProtonCoreCryptoGoInterface.CryptoPlainMessage?, signature: ProtonCoreCryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64) throws {
        try verifyDetached(message?.toGoLibsType,
                           signature: signature?.toGoLibsType,
                           verifyTime: verifyTime)
    }

    public func add(_ key: ProtonCoreCryptoGoInterface.CryptoKey?) throws {
        try add(key?.toGoLibsType)
    }

    public func copy(_ error: NSErrorPointer) -> ProtonCoreCryptoGoInterface.CryptoKeyRing? {
        let value: GoLibs.CryptoKeyRing? = copy(error)
        return value
    }

    public func decrypt(_ message: ProtonCoreCryptoGoInterface.CryptoPGPMessage?, verifyKey: ProtonCoreCryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCoreCryptoGoInterface.CryptoPlainMessage {
        try decrypt(message?.toGoLibsType,
                    verifyKey: verifyKey?.toGoLibsType,
                    verifyTime: verifyTime)
    }

    public func decryptAttachment(_ message: ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage?) throws -> ProtonCoreCryptoGoInterface.CryptoPlainMessage {
        try decryptAttachment(message?.toGoLibsType)
    }

    public func encryptSessionKey(_ sk: ProtonCoreCryptoGoInterface.CryptoSessionKey?) throws -> Data {
        try encryptSessionKey(sk?.toGoLibsType)
    }
}

// MARK: - CryptoPGPMessage

extension ProtonCoreCryptoGoInterface.CryptoPGPMessage {
    var toGoLibsType: GoLibs.CryptoPGPMessage {
        forceCast(object: self, to: GoLibs.CryptoPGPMessage.self)
    }
}

extension GoLibs.CryptoPGPMessage: ProtonCoreCryptoGoInterface.CryptoPGPMessage {
    public func separateKeyAndData(_ p0: Int, p1: Int) throws -> ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try separateKeyAndData(p0, p1: p1)
        return value
    }

    public func splitMessage() throws -> ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try splitMessage()
        return value
    }
}

// MARK: - CryptoPGPSplitMessage

extension ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage {
    var toGoLibsType: GoLibs.CryptoPGPSplitMessage {
        forceCast(object: self, to: GoLibs.CryptoPGPSplitMessage.self)
    }
}

extension GoLibs.CryptoPGPSplitMessage: ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage {
    public func getPGPMessage() -> ProtonCoreCryptoGoInterface.CryptoPGPMessage? {
        let value: GoLibs.CryptoPGPMessage? = getPGPMessage()
        return value
    }
}

// MARK: - CryptoPlainMessage

extension ProtonCoreCryptoGoInterface.CryptoPlainMessage {
    var toGoLibsType: GoLibs.CryptoPlainMessage {
        forceCast(object: self, to: GoLibs.CryptoPlainMessage.self)
    }
}

extension GoLibs.CryptoPlainMessage: ProtonCoreCryptoGoInterface.CryptoPlainMessage {}

// MARK: - CryptoClearTextMessage

extension ProtonCoreCryptoGoInterface.CryptoClearTextMessage {
    var toGoLibsType: GoLibs.CryptoClearTextMessage {
        forceCast(object: self, to: GoLibs.CryptoClearTextMessage.self)
    }
}

extension GoLibs.CryptoClearTextMessage: ProtonCoreCryptoGoInterface.CryptoClearTextMessage {}

// MARK: - HelperGo2IOSReader

extension ProtonCoreCryptoGoInterface.HelperGo2IOSReader {
    var toGoLibsType: GoLibs.HelperGo2IOSReader {
        forceCast(object: self, to: GoLibs.HelperGo2IOSReader.self)
    }
}

extension GoLibs.HelperGo2IOSReader: ProtonCoreCryptoGoInterface.HelperGo2IOSReader {
    public func read(_ max: Int) throws -> ProtonCoreCryptoGoInterface.HelperMobileReadResult {
        let value: GoLibs.HelperMobileReadResult = try read(max)
        return value
    }
}

// MARK: - HelperMobileReadResult

extension ProtonCoreCryptoGoInterface.HelperMobileReadResult {
    var toGoLibsType: GoLibs.HelperMobileReadResult {
        forceCast(object: self, to: GoLibs.HelperMobileReadResult.self)
    }
}

extension GoLibs.HelperMobileReadResult: ProtonCoreCryptoGoInterface.HelperMobileReadResult {}

// MARK: - HelperMobile2GoReader

extension ProtonCoreCryptoGoInterface.HelperMobile2GoReader {
    var toGoLibsType: GoLibs.HelperMobile2GoReader {
        forceCast(object: self, to: GoLibs.HelperMobile2GoReader.self)
    }
}

extension GoLibs.HelperMobile2GoReader: ProtonCoreCryptoGoInterface.HelperMobile2GoReader {}

// MARK: - HelperMobile2GoWriter

extension ProtonCoreCryptoGoInterface.HelperMobile2GoWriter {
    var toGoLibsType: GoLibs.HelperMobile2GoWriter {
        forceCast(object: self, to: GoLibs.HelperMobile2GoWriter.self)
    }
}

extension GoLibs.HelperMobile2GoWriter: ProtonCoreCryptoGoInterface.HelperMobile2GoWriter {}

// MARK: - HelperMobile2GoWriterWithSHA256

extension ProtonCoreCryptoGoInterface.HelperMobile2GoWriterWithSHA256 {
    var toGoLibsType: GoLibs.HelperMobile2GoWriterWithSHA256 {
        forceCast(object: self, to: GoLibs.HelperMobile2GoWriterWithSHA256.self)
    }
}

extension GoLibs.HelperMobile2GoWriterWithSHA256: ProtonCoreCryptoGoInterface.HelperMobile2GoWriterWithSHA256 {}

// MARK: - CryptoPGPSignature

extension ProtonCoreCryptoGoInterface.CryptoPGPSignature {
    var toGoLibsType: GoLibs.CryptoPGPSignature {
        forceCast(object: self, to: GoLibs.CryptoPGPSignature.self)
    }
}

extension GoLibs.CryptoPGPSignature: ProtonCoreCryptoGoInterface.CryptoPGPSignature {}

// MARK: - CryptoAttachmentProcessor

extension ProtonCoreCryptoGoInterface.CryptoAttachmentProcessor {
    var toGoLibsType: GoLibs.CryptoAttachmentProcessor {
        forceCast(object: self, to: GoLibs.CryptoAttachmentProcessor.self)
    }
}

extension GoLibs.CryptoAttachmentProcessor: ProtonCoreCryptoGoInterface.CryptoAttachmentProcessor {
    public func finish() throws -> ProtonCoreCryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try finish()
        return value
    }
}

// MARK: - HelperExplicitVerifyMessage

extension ProtonCoreCryptoGoInterface.HelperExplicitVerifyMessage {
    var toGoLibsType: GoLibs.HelperExplicitVerifyMessage {
        forceCast(object: self, to: GoLibs.HelperExplicitVerifyMessage.self)
    }
}

extension GoLibs.HelperExplicitVerifyMessage: ProtonCoreCryptoGoInterface.HelperExplicitVerifyMessage {
    public var messageGoCrypto: ProtonCoreCryptoGoInterface.CryptoPlainMessage? {
        message
    }

    public var signatureVerificationErrorGoCrypto: ProtonCoreCryptoGoInterface.CryptoSignatureVerificationError? {
        signatureVerificationError
    }
}

// MARK: - CryptoSignatureVerificationError

extension ProtonCoreCryptoGoInterface.CryptoSignatureVerificationError {
    var toGoLibsType: GoLibs.CryptoSignatureVerificationError {
        forceCast(object: self, to: GoLibs.CryptoSignatureVerificationError.self)
    }
}

extension GoLibs.CryptoSignatureVerificationError: ProtonCoreCryptoGoInterface.CryptoSignatureVerificationError {}

// MARK: - CryptoSigningContext

extension ProtonCoreCryptoGoInterface.CryptoSigningContext {
    var toGoLibsType: GoLibs.CryptoSigningContext {
        forceCast(object: self, to: GoLibs.CryptoSigningContext.self)
    }
}

extension GoLibs.CryptoSigningContext: ProtonCoreCryptoGoInterface.CryptoSigningContext {}

// MARK: - CryptoVerificationContext

extension ProtonCoreCryptoGoInterface.CryptoVerificationContext {
    var toGoLibsType: GoLibs.CryptoVerificationContext {
        forceCast(object: self, to: GoLibs.CryptoVerificationContext.self)
    }
}

extension GoLibs.CryptoVerificationContext: ProtonCoreCryptoGoInterface.CryptoVerificationContext {}


// MARK: - SrpAuth
extension GoLibs.SrpAuth: ProtonCoreCryptoGoInterface.SrpAuth {
    public func generateProofs(_ bitLength: Int) throws -> ProtonCoreCryptoGoInterface.SrpProofs {
        let value: GoLibs.SrpProofs = try generateProofs(bitLength)
        return value
    }
}

// MARK: - SrpProofs
extension GoLibs.SrpProofs: ProtonCoreCryptoGoInterface.SrpProofs {}

// MARK: - SrpServer
extension GoLibs.SrpServer: ProtonCoreCryptoGoInterface.SrpServer {}

// MARK: - CryptoEncryptSplitResult

extension ProtonCoreCryptoGoInterface.CryptoEncryptSplitResult {
    var toGoLibsType: GoLibs.CryptoEncryptSplitResult {
        forceCast(object: self, to: GoLibs.CryptoEncryptSplitResult.self)
    }
}

extension GoLibs.CryptoEncryptSplitResult: ProtonCoreCryptoGoInterface.CryptoEncryptSplitResult {}

// MARK: - CryptoPlainMessageMetadata

extension ProtonCoreCryptoGoInterface.CryptoPlainMessageMetadata {
    var toGoLibsType: GoLibs.CryptoPlainMessageMetadata {
        forceCast(object: self, to: GoLibs.CryptoPlainMessageMetadata.self)
    }
}

extension GoLibs.CryptoPlainMessageMetadata: ProtonCoreCryptoGoInterface.CryptoPlainMessageMetadata {}

// MARK: - CryptoPlainMessageReader

extension ProtonCoreCryptoGoInterface.CryptoPlainMessageReader {
    var toGoLibsType: GoLibs.CryptoPlainMessageReader {
        forceCast(object: self, to: GoLibs.CryptoPlainMessageReader.self)
    }
}

extension GoLibs.CryptoPlainMessageReader: ProtonCoreCryptoGoInterface.CryptoPlainMessageReader {
    public func getMetadata() -> ProtonCoreCryptoGoInterface.CryptoPlainMessageMetadata? {
        let value: GoLibs.CryptoPlainMessageMetadata? = getMetadata()
        return value
    }
}
