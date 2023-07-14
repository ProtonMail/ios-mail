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
import ProtonCore_CryptoGoInterface

private func forceCast<CryptoGoType, GoLibsType>(object: CryptoGoType, to _: GoLibsType.Type) -> GoLibsType {
    assert(GoLibsType.self is CryptoGoType.Type,
           """
           Programmer's error: \(GoLibsType.self) is expected to conform to \(CryptoGoType.self).
           Have you forget to provide the protocol conformance?
           """)
    return object as! GoLibsType
}

// MARK: - CryptoKey

extension ProtonCore_CryptoGoInterface.CryptoKey {
    var toGoLibsType: GoLibs.CryptoKey {
        forceCast(object: self, to: GoLibs.CryptoKey.self)
    }
}

extension GoLibs.CryptoKey: ProtonCore_CryptoGoInterface.CryptoKey {
    public func copy(_ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        let value: GoLibs.CryptoKey? = copy(error)
        return value
    }

    public func lock(_ passphrase: Data?) throws -> ProtonCore_CryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try lock(passphrase)
        return value
    }

    public func toPublic() throws -> ProtonCore_CryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try toPublic()
        return value
    }

    public func unlock(_ passphrase: Data?) throws -> ProtonCore_CryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try unlock(passphrase)
        return value
    }
}

// MARK: - CryptoSessionKey

extension ProtonCore_CryptoGoInterface.CryptoSessionKey {
    var toGoLibsType: GoLibs.CryptoSessionKey {
        forceCast(object: self, to: GoLibs.CryptoSessionKey.self)
    }
}

extension GoLibs.CryptoSessionKey: ProtonCore_CryptoGoInterface.CryptoSessionKey {

    public func decryptStream(_ dataPacketReader: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?, verifyKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCore_CryptoGoInterface.CryptoPlainMessageReader {
        let value: GoLibs.CryptoPlainMessageReader = try decryptStream(
            dataPacketReader?.toGoLibsType,
            verifyKeyRing: verifyKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
        return value
    }

    public func encryptStream(_ dataPacketWriter: ProtonCore_CryptoGoInterface.CryptoWriterProtocol?, plainMessageMetadata: ProtonCore_CryptoGoInterface.CryptoPlainMessageMetadata?, sign signKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?) throws -> ProtonCore_CryptoGoInterface.CryptoWriteCloserProtocol {
        let value: GoLibs.CryptoWriteCloserProtocol = try encryptStream(
            dataPacketWriter?.toGoLibsType,
            plainMessageMetadata: plainMessageMetadata?.toGoLibsType,
            sign: signKeyRing?.toGoLibsType
        )
        return value.toCryptoGoType
    }

    public func decrypt(_ dataPacket: Data?) throws -> ProtonCore_CryptoGoInterface.CryptoPlainMessage {
        let value: GoLibs.CryptoPlainMessage = try decrypt(dataPacket)
        return value
    }

    public func decryptAndVerify(_ dataPacket: Data?, verifyKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCore_CryptoGoInterface.CryptoPlainMessage {
        let value: GoLibs.CryptoPlainMessage = try decryptAndVerify(
            dataPacket,
            verifyKeyRing: verifyKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
        return value
    }

    public func encrypt(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?) throws -> Data {
        try encrypt(message?.toGoLibsType)
    }

    public func encryptAndSign(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, sign signKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?) throws -> Data {
        try encryptAndSign(message?.toGoLibsType, sign: signKeyRing?.toGoLibsType)
    }

    public func encrypt(withCompression message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?) throws -> Data {
        try encrypt(withCompression: message?.toGoLibsType)
    }
}

// MARK: - CryptoKeyRing

extension ProtonCore_CryptoGoInterface.CryptoKeyRing {
    var toGoLibsType: GoLibs.CryptoKeyRing {
        forceCast(object: self, to: GoLibs.CryptoKeyRing.self)
    }
}



extension GoLibs.CryptoKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing {
    public func decryptMIMEMessage(_ message: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, verifyKey: ProtonCore_CryptoGoInterface.CryptoKeyRing?, callbacks: ProtonCore_CryptoGoInterface.CryptoMIMECallbacksProtocol?, verifyTime: Int64) {
        decryptMIMEMessage(
            message?.toGoLibsType,
            verifyKey: verifyKey?.toGoLibsType,
            callbacks: callbacks?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func getKey(_ n: Int) throws -> ProtonCore_CryptoGoInterface.CryptoKey {
        let value: GoLibs.CryptoKey = try getKey(n)
        return value
    }

    public func signDetachedEncryptedStream(_ message: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?, encryptionKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try signDetachedEncryptedStream(
            message?.toGoLibsType,
            encryptionKeyRing: encryptionKeyRing?.toGoLibsType
        )
        return value
    }

    public func verifyDetachedEncrypted(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, encryptedSignature: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, decryptionKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws {
        try verifyDetachedEncrypted(
            message?.toGoLibsType,
            encryptedSignature: encryptedSignature?.toGoLibsType,
            decryptionKeyRing: decryptionKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func verifyDetachedEncryptedStream(_ message: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?, encryptedSignature: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, decryptionKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws {
        try verifyDetachedEncryptedStream(
            message?.toGoLibsType,
            encryptedSignature: encryptedSignature?.toGoLibsType,
            decryptionKeyRing: decryptionKeyRing?.toGoLibsType,
            verifyTime: verifyTime
        )
    }

    public func encryptSplitStream(_ dataPacketWriter: ProtonCore_CryptoGoInterface.CryptoWriterProtocol?, plainMessageMetadata: ProtonCore_CryptoGoInterface.CryptoPlainMessageMetadata?, sign signKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?) throws -> ProtonCore_CryptoGoInterface.CryptoEncryptSplitResult {
        let value: GoLibs.CryptoEncryptSplitResult = try encryptSplitStream(
            dataPacketWriter?.toGoLibsType,
            plainMessageMetadata: plainMessageMetadata?.toGoLibsType,
            sign: signKeyRing?.toGoLibsType
        )
        return value
    }

    public func encrypt(withContext message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, privateKey: ProtonCore_CryptoGoInterface.CryptoKeyRing?, signingContext: ProtonCore_CryptoGoInterface.CryptoSigningContext?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try encrypt(
            withContext: message?.toGoLibsType,
            privateKey: privateKey?.toGoLibsType,
            signingContext: signingContext?.toGoLibsType
        )
        return value
    }

    public func newLowMemoryAttachmentProcessor(_ estimatedSize: Int, filename: String?) throws -> ProtonCore_CryptoGoInterface.CryptoAttachmentProcessor {
        let value: GoLibs.CryptoAttachmentProcessor = try newLowMemoryAttachmentProcessor(estimatedSize, filename: filename)
        return value
    }

    public func signDetachedStream(withContext message: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?, context: ProtonCore_CryptoGoInterface.CryptoSigningContext?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetachedStream(
            withContext: message?.toGoLibsType,
            context: context?.toGoLibsType
        )
        return value
    }

    public func signDetached(withContext message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, context: ProtonCore_CryptoGoInterface.CryptoSigningContext?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetached(
            withContext: message?.toGoLibsType,
            context: context?.toGoLibsType
        )
        return value
    }

    public func verifyDetachedStream(withContext message: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?, signature: ProtonCore_CryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64, verificationContext: ProtonCore_CryptoGoInterface.CryptoVerificationContext?) throws {
        try verifyDetachedStream(
            withContext: message?.toGoLibsType,
            signature: signature?.toGoLibsType,
            verifyTime: verifyTime,
            verificationContext: verificationContext?.toGoLibsType
        )
    }

    public func verifyDetached(withContext message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, signature: ProtonCore_CryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64, verificationContext: ProtonCore_CryptoGoInterface.CryptoVerificationContext?) throws {
        try verifyDetached(
            withContext: message?.toGoLibsType,
            signature: signature?.toGoLibsType,
            verifyTime: verifyTime,
            verificationContext: verificationContext?.toGoLibsType
        )
    }


    public func decryptSessionKey(_ keyPacket: Data?) throws -> ProtonCore_CryptoGoInterface.CryptoSessionKey {
        let value: GoLibs.CryptoSessionKey = try decryptSessionKey(keyPacket)
        return value
    }

    public func encrypt(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, privateKey: ProtonCore_CryptoGoInterface.CryptoKeyRing?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPMessage {
        let value: GoLibs.CryptoPGPMessage = try encrypt(message?.toGoLibsType,
                                                         privateKey: privateKey?.toGoLibsType)
        return value
    }

    public func signDetached(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?) throws -> ProtonCore_CryptoGoInterface.CryptoPGPSignature {
        let value: GoLibs.CryptoPGPSignature = try signDetached(message?.toGoLibsType)
        return value
    }

    public func verifyDetached(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, signature: ProtonCore_CryptoGoInterface.CryptoPGPSignature?, verifyTime: Int64) throws {
        try verifyDetached(message?.toGoLibsType,
                           signature: signature?.toGoLibsType,
                           verifyTime: verifyTime)
    }

    public func add(_ key: ProtonCore_CryptoGoInterface.CryptoKey?) throws {
        try add(key?.toGoLibsType)
    }

    public func copy(_ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKeyRing? {
        let value: GoLibs.CryptoKeyRing? = copy(error)
        return value
    }

    public func decrypt(_ message: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, verifyKey: ProtonCore_CryptoGoInterface.CryptoKeyRing?, verifyTime: Int64) throws -> ProtonCore_CryptoGoInterface.CryptoPlainMessage {
        try decrypt(message?.toGoLibsType,
                    verifyKey: verifyKey?.toGoLibsType,
                    verifyTime: verifyTime)
    }

    public func decryptAttachment(_ message: ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage?) throws -> ProtonCore_CryptoGoInterface.CryptoPlainMessage {
        try decryptAttachment(message?.toGoLibsType)
    }

    public func encryptSessionKey(_ sk: ProtonCore_CryptoGoInterface.CryptoSessionKey?) throws -> Data {
        try encryptSessionKey(sk?.toGoLibsType)
    }
}

// MARK: - CryptoPGPMessage

extension ProtonCore_CryptoGoInterface.CryptoPGPMessage {
    var toGoLibsType: GoLibs.CryptoPGPMessage {
        forceCast(object: self, to: GoLibs.CryptoPGPMessage.self)
    }
}

extension GoLibs.CryptoPGPMessage: ProtonCore_CryptoGoInterface.CryptoPGPMessage {
    public func separateKeyAndData(_ p0: Int, p1: Int) throws -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try separateKeyAndData(p0, p1: p1)
        return value
    }

    public func splitMessage() throws -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try splitMessage()
        return value
    }
}

// MARK: - CryptoPGPSplitMessage

extension ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage {
    var toGoLibsType: GoLibs.CryptoPGPSplitMessage {
        forceCast(object: self, to: GoLibs.CryptoPGPSplitMessage.self)
    }
}

extension GoLibs.CryptoPGPSplitMessage: ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage {
    public func getPGPMessage() -> ProtonCore_CryptoGoInterface.CryptoPGPMessage? {
        let value: GoLibs.CryptoPGPMessage? = getPGPMessage()
        return value
    }
}

// MARK: - CryptoPlainMessage

extension ProtonCore_CryptoGoInterface.CryptoPlainMessage {
    var toGoLibsType: GoLibs.CryptoPlainMessage {
        forceCast(object: self, to: GoLibs.CryptoPlainMessage.self)
    }
}

extension GoLibs.CryptoPlainMessage: ProtonCore_CryptoGoInterface.CryptoPlainMessage {}

// MARK: - CryptoClearTextMessage

extension ProtonCore_CryptoGoInterface.CryptoClearTextMessage {
    var toGoLibsType: GoLibs.CryptoClearTextMessage {
        forceCast(object: self, to: GoLibs.CryptoClearTextMessage.self)
    }
}

extension GoLibs.CryptoClearTextMessage: ProtonCore_CryptoGoInterface.CryptoClearTextMessage {}

// MARK: - HelperGo2IOSReader

extension ProtonCore_CryptoGoInterface.HelperGo2IOSReader {
    var toGoLibsType: GoLibs.HelperGo2IOSReader {
        forceCast(object: self, to: GoLibs.HelperGo2IOSReader.self)
    }
}

extension GoLibs.HelperGo2IOSReader: ProtonCore_CryptoGoInterface.HelperGo2IOSReader {
    public func read(_ max: Int) throws -> ProtonCore_CryptoGoInterface.HelperMobileReadResult {
        let value: GoLibs.HelperMobileReadResult = try read(max)
        return value
    }
}

// MARK: - HelperMobileReadResult

extension ProtonCore_CryptoGoInterface.HelperMobileReadResult {
    var toGoLibsType: GoLibs.HelperMobileReadResult {
        forceCast(object: self, to: GoLibs.HelperMobileReadResult.self)
    }
}

extension GoLibs.HelperMobileReadResult: ProtonCore_CryptoGoInterface.HelperMobileReadResult {}

// MARK: - HelperMobile2GoReader

extension ProtonCore_CryptoGoInterface.HelperMobile2GoReader {
    var toGoLibsType: GoLibs.HelperMobile2GoReader {
        forceCast(object: self, to: GoLibs.HelperMobile2GoReader.self)
    }
}

extension GoLibs.HelperMobile2GoReader: ProtonCore_CryptoGoInterface.HelperMobile2GoReader {}

// MARK: - HelperMobile2GoWriter

extension ProtonCore_CryptoGoInterface.HelperMobile2GoWriter {
    var toGoLibsType: GoLibs.HelperMobile2GoWriter {
        forceCast(object: self, to: GoLibs.HelperMobile2GoWriter.self)
    }
}

extension GoLibs.HelperMobile2GoWriter: ProtonCore_CryptoGoInterface.HelperMobile2GoWriter {}

// MARK: - HelperMobile2GoWriterWithSHA256

extension ProtonCore_CryptoGoInterface.HelperMobile2GoWriterWithSHA256 {
    var toGoLibsType: GoLibs.HelperMobile2GoWriterWithSHA256 {
        forceCast(object: self, to: GoLibs.HelperMobile2GoWriterWithSHA256.self)
    }
}

extension GoLibs.HelperMobile2GoWriterWithSHA256: ProtonCore_CryptoGoInterface.HelperMobile2GoWriterWithSHA256 {}

// MARK: - CryptoPGPSignature

extension ProtonCore_CryptoGoInterface.CryptoPGPSignature {
    var toGoLibsType: GoLibs.CryptoPGPSignature {
        forceCast(object: self, to: GoLibs.CryptoPGPSignature.self)
    }
}

extension GoLibs.CryptoPGPSignature: ProtonCore_CryptoGoInterface.CryptoPGPSignature {}

// MARK: - CryptoAttachmentProcessor

extension ProtonCore_CryptoGoInterface.CryptoAttachmentProcessor {
    var toGoLibsType: GoLibs.CryptoAttachmentProcessor {
        forceCast(object: self, to: GoLibs.CryptoAttachmentProcessor.self)
    }
}

extension GoLibs.CryptoAttachmentProcessor: ProtonCore_CryptoGoInterface.CryptoAttachmentProcessor {
    public func finish() throws -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage {
        let value: GoLibs.CryptoPGPSplitMessage = try finish()
        return value
    }
}

// MARK: - HelperExplicitVerifyMessage

extension ProtonCore_CryptoGoInterface.HelperExplicitVerifyMessage {
    var toGoLibsType: GoLibs.HelperExplicitVerifyMessage {
        forceCast(object: self, to: GoLibs.HelperExplicitVerifyMessage.self)
    }
}

extension GoLibs.HelperExplicitVerifyMessage: ProtonCore_CryptoGoInterface.HelperExplicitVerifyMessage {
    public var messageGoCrypto: ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        message
    }

    public var signatureVerificationErrorGoCrypto: ProtonCore_CryptoGoInterface.CryptoSignatureVerificationError? {
        signatureVerificationError
    }
}

// MARK: - CryptoSignatureVerificationError

extension ProtonCore_CryptoGoInterface.CryptoSignatureVerificationError {
    var toGoLibsType: GoLibs.CryptoSignatureVerificationError {
        forceCast(object: self, to: GoLibs.CryptoSignatureVerificationError.self)
    }
}

extension GoLibs.CryptoSignatureVerificationError: ProtonCore_CryptoGoInterface.CryptoSignatureVerificationError {}

// MARK: - CryptoSigningContext

extension ProtonCore_CryptoGoInterface.CryptoSigningContext {
    var toGoLibsType: GoLibs.CryptoSigningContext {
        forceCast(object: self, to: GoLibs.CryptoSigningContext.self)
    }
}

extension GoLibs.CryptoSigningContext: ProtonCore_CryptoGoInterface.CryptoSigningContext {}

// MARK: - CryptoVerificationContext

extension ProtonCore_CryptoGoInterface.CryptoVerificationContext {
    var toGoLibsType: GoLibs.CryptoVerificationContext {
        forceCast(object: self, to: GoLibs.CryptoVerificationContext.self)
    }
}

extension GoLibs.CryptoVerificationContext: ProtonCore_CryptoGoInterface.CryptoVerificationContext {}


// MARK: - SrpAuth
extension GoLibs.SrpAuth: ProtonCore_CryptoGoInterface.SrpAuth {
    public func generateProofs(_ bitLength: Int) throws -> ProtonCore_CryptoGoInterface.SrpProofs {
        let value: GoLibs.SrpProofs = try generateProofs(bitLength)
        return value
    }
}

// MARK: - SrpProofs
extension GoLibs.SrpProofs: ProtonCore_CryptoGoInterface.SrpProofs {}

// MARK: - SrpServer
extension GoLibs.SrpServer: ProtonCore_CryptoGoInterface.SrpServer {}

// MARK: - CryptoEncryptSplitResult

extension ProtonCore_CryptoGoInterface.CryptoEncryptSplitResult {
    var toGoLibsType: GoLibs.CryptoEncryptSplitResult {
        forceCast(object: self, to: GoLibs.CryptoEncryptSplitResult.self)
    }
}

extension GoLibs.CryptoEncryptSplitResult: ProtonCore_CryptoGoInterface.CryptoEncryptSplitResult {}

// MARK: - CryptoPlainMessageMetadata

extension ProtonCore_CryptoGoInterface.CryptoPlainMessageMetadata {
    var toGoLibsType: GoLibs.CryptoPlainMessageMetadata {
        forceCast(object: self, to: GoLibs.CryptoPlainMessageMetadata.self)
    }
}

extension GoLibs.CryptoPlainMessageMetadata: ProtonCore_CryptoGoInterface.CryptoPlainMessageMetadata {}

// MARK: - CryptoPlainMessageReader

extension ProtonCore_CryptoGoInterface.CryptoPlainMessageReader {
    var toGoLibsType: GoLibs.CryptoPlainMessageReader {
        forceCast(object: self, to: GoLibs.CryptoPlainMessageReader.self)
    }
}

extension GoLibs.CryptoPlainMessageReader: ProtonCore_CryptoGoInterface.CryptoPlainMessageReader {
    public func getMetadata() -> ProtonCore_CryptoGoInterface.CryptoPlainMessageMetadata? {
        let value: GoLibs.CryptoPlainMessageMetadata? = getMetadata()
        return value
    }
}
