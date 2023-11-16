//
//  CryptoGoClasses.swift
//  ProtonCore-CryptoGoInterface - Created on 24/05/2023.
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

public protocol CryptoKey {
    func armor(_ error: NSErrorPointer) -> String
    func armor(withCustomHeaders comment: String?, version: String?, error: NSErrorPointer) -> String
    func canEncrypt() -> Bool
    func canVerify() -> Bool
    func check(_ ret0_: UnsafeMutablePointer<ObjCBool>?) throws
    func clearPrivateParams() -> Bool
    func copy(_ error: NSErrorPointer) -> CryptoKey?
    func getArmoredPublicKey(_ error: NSErrorPointer) -> String
    func getArmoredPublicKey(withCustomHeaders comment: String?, version: String?, error: NSErrorPointer) -> String
    func getFingerprint() -> String
    func getHexKeyID() -> String
    func getPublicKey() throws -> Data
    func isExpired() -> Bool
    func isLocked(_ ret0_: UnsafeMutablePointer<ObjCBool>?) throws
    func isPrivate() -> Bool
    func isRevoked() -> Bool
    func isUnlocked(_ ret0_: UnsafeMutablePointer<ObjCBool>?) throws
    func lock(_ passphrase: Data?) throws -> CryptoKey
    func printFingerprints()
    func serialize() throws -> Data
    func toPublic() throws -> CryptoKey
    func unlock(_ passphrase: Data?) throws -> CryptoKey
}

public protocol CryptoSessionKey {
    var key: Data? { get set }
    var algo: String { get set }
    func clear() -> Bool
    func decrypt(_ dataPacket: Data?) throws -> CryptoPlainMessage
    func decryptAndVerify(_ dataPacket: Data?, verifyKeyRing: CryptoKeyRing?, verifyTime: Int64) throws -> CryptoPlainMessage
    func decryptStream(_ dataPacketReader: CryptoReaderProtocol?, verifyKeyRing: CryptoKeyRing?, verifyTime: Int64) throws -> CryptoPlainMessageReader
    func encrypt(_ message: CryptoPlainMessage?) throws -> Data
    func encryptAndSign(_ message: CryptoPlainMessage?, sign signKeyRing: CryptoKeyRing?) throws -> Data
    func encryptStream(_ dataPacketWriter: CryptoWriterProtocol?, plainMessageMetadata: CryptoPlainMessageMetadata?, sign signKeyRing: CryptoKeyRing?) throws -> CryptoWriteCloserProtocol
    func encrypt(withCompression message: CryptoPlainMessage?) throws -> Data
    func getBase64Key() -> String
}

public protocol CryptoKeyRing {
    var firstKeyID: String { get set }
    func add(_ key: CryptoKey?) throws
    func canEncrypt() -> Bool
    func canVerify() -> Bool
    func clearPrivateParams()
    func copy(_ error: NSErrorPointer) -> CryptoKeyRing?
    func countDecryptionEntities() -> Int
    func countEntities() -> Int
    func decrypt(_ message: CryptoPGPMessage?, verifyKey: CryptoKeyRing?, verifyTime: Int64) throws -> CryptoPlainMessage
    func decryptAttachment(_ message: CryptoPGPSplitMessage?) throws -> CryptoPlainMessage
    func decryptMIMEMessage(_ message: CryptoPGPMessage?, verifyKey: CryptoKeyRing?, callbacks: CryptoMIMECallbacksProtocol?, verifyTime: Int64)
    func decryptSessionKey(_ keyPacket: Data?) throws -> CryptoSessionKey
    func encrypt(_ message: CryptoPlainMessage?, privateKey: CryptoKeyRing?) throws -> CryptoPGPMessage
    func encrypt(withCompression message: CryptoPlainMessage?, privateKey: CryptoKeyRing?) throws -> CryptoPGPMessage
    func encryptSessionKey(_ sk: CryptoSessionKey?) throws -> Data
    func encryptSplitStream(_ dataPacketWriter: CryptoWriterProtocol?, plainMessageMetadata: CryptoPlainMessageMetadata?, sign signKeyRing: CryptoKeyRing?) throws -> CryptoEncryptSplitResult
    func encrypt(withContext message: CryptoPlainMessage?, privateKey: CryptoKeyRing?, signingContext: CryptoSigningContext?) throws -> CryptoPGPMessage
    func getKey(_ n: Int) throws -> CryptoKey
    func newLowMemoryAttachmentProcessor(_ estimatedSize: Int, filename: String?) throws -> CryptoAttachmentProcessor
    func signDetached(_ message: CryptoPlainMessage?) throws -> CryptoPGPSignature
    func signDetachedEncryptedStream(_ message: CryptoReaderProtocol?, encryptionKeyRing: CryptoKeyRing?) throws -> CryptoPGPMessage
    func signDetachedStream(withContext message: CryptoReaderProtocol?, context: CryptoSigningContext?) throws -> CryptoPGPSignature
    func signDetached(withContext message: CryptoPlainMessage?, context: CryptoSigningContext?) throws -> CryptoPGPSignature
    func verifyDetached(_ message: CryptoPlainMessage?, signature: CryptoPGPSignature?, verifyTime: Int64) throws
    func verifyDetachedEncrypted(_ message: CryptoPlainMessage?, encryptedSignature: CryptoPGPMessage?, decryptionKeyRing: CryptoKeyRing?, verifyTime: Int64) throws
    func verifyDetachedEncryptedStream(_ message: CryptoReaderProtocol?, encryptedSignature: CryptoPGPMessage?, decryptionKeyRing: CryptoKeyRing?, verifyTime: Int64) throws
    func verifyDetachedStream(withContext message: CryptoReaderProtocol?, signature: CryptoPGPSignature?, verifyTime: Int64, verificationContext: CryptoVerificationContext?) throws
    func verifyDetached(withContext message: CryptoPlainMessage?, signature: CryptoPGPSignature?, verifyTime: Int64, verificationContext: CryptoVerificationContext?) throws
}

public protocol CryptoPlainMessage {
    var data: Data? { get set }
    var textType: Bool { get set }
    var filename: String { get set }
    func getBase64() -> String
    func getBinary() -> Data?
    func getFilename() -> String
    func getString() -> String
    func isBinary() -> Bool
    func isText() -> Bool
}

public protocol CryptoPGPMessage {
    var data: Data? { get set }
    func getArmored(_ error: NSErrorPointer) -> String
    func getArmoredWithCustomHeaders(_ comment: String?, version: String?, error: NSErrorPointer) -> String
    func getBinary() -> Data?
    func separateKeyAndData(_ p0: Int, p1: Int) throws -> CryptoPGPSplitMessage
    func splitMessage() throws -> CryptoPGPSplitMessage
}

public protocol CryptoPGPSplitMessage {
    var dataPacket: Data? { get set }
    var keyPacket: Data? { get set }
    func getArmored(_ error: NSErrorPointer) -> String
    func getBinary() -> Data?
    func getBinaryDataPacket() -> Data?
    func getBinaryKeyPacket() -> Data?
    func getPGPMessage() -> CryptoPGPMessage?
}

public protocol CryptoClearTextMessage {
    var data: Data? { get set }
    var signature: Data? { get set }
    func getArmored(_ error: NSErrorPointer) -> String
    func getBinary() -> Data?
    func getBinarySignature() -> Data?
    func getString() -> String
}

public protocol CryptoPGPSignature {
    var data: Data? { get set }
    func getArmored(_ error: NSErrorPointer) -> String
    func getBinary() -> Data?
}

public protocol CryptoAttachmentProcessor {
    func finish() throws -> CryptoPGPSplitMessage
    func process(_ plainData: Data?)
}

public protocol HelperExplicitVerifyMessage {
    var messageGoCrypto: CryptoPlainMessage? { get }
    var signatureVerificationErrorGoCrypto: CryptoSignatureVerificationError? { get }
}

public protocol CryptoSignatureVerificationError {
    var status: Int { get set }
    var message: String { get set }
    var cause: Error? { get set }
    func error() -> String
    func unwrap() throws
}

public protocol CryptoPlainMessageReader: CryptoReaderProtocol {
    func getMetadata() -> CryptoPlainMessageMetadata?
    func read(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws
    func verifySignature() throws
}

@objc public protocol HelperMobileReadResult {
    var n: Int { get set }
    var isEOF: Bool { get set }
    var data: Data? { get set }
}

public protocol HelperMobile2GoReader: CryptoReaderProtocol {
    func read(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws
}

public protocol HelperMobile2GoWriter: CryptoWriterProtocol {
    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws
}

public protocol HelperMobile2GoWriterWithSHA256: CryptoWriterProtocol {
    func getSHA256() -> Data?
    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws
}

public protocol HelperGo2IOSReader {
    func read(_ max: Int) throws -> HelperMobileReadResult
}

public protocol CryptoSigningContext {
    var value: String { get set }
    var isCritical: Bool { get set }
}

public protocol CryptoVerificationContext {
    var value: String { get set }
    var isRequired: Bool { get set }
    var requiredAfter: Int64 { get set }
}

public protocol CryptoEncryptSplitResult {
    func close() throws
    func getKeyPacket() throws -> Data
    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws
}

public protocol CryptoPlainMessageMetadata {
    var isBinary: Bool { get set }
    var filename: String { get set }
    var modTime: Int64 { get set }
}

@objc public protocol CryptoMIMECallbacksProtocol {
    func onAttachment(_ headers: String?, data: Data?)
    func onBody(_ body: String?, mimetype: String?)
    func onEncryptedHeaders(_ headers: String?)
    func onError(_ err: Error?)
    func onVerified(_ verified: Int)
}

public protocol SrpAuth {
    var modulus: Data? { get set }
    var serverEphemeral: Data? {get set}
    var hashedPassword: Data? {get set}
    var version: Int {get set}
    func generateProofs(_ bitLength: Int) throws -> SrpProofs
    func generateVerifier(_ bitLength: Int) throws -> Data
}

public protocol SrpProofs {
    var clientProof: Data? { get set }
    var clientEphemeral: Data? { get set}
    var expectedServerProof: Data? { get set}
}

public protocol SrpServer {
    func generateChallenge() throws -> Data
    /**
     * GetSharedSession returns the shared secret as byte if the session has concluded in valid state.
     */
    func getSharedSession() throws -> Data

    /**
     * IsCompleted returns true if the exchange has been concluded in valid state.
     */
    func isCompleted() -> Bool

    /**
     * VerifyProofs Verifies the client proof and - if valid - generates the shared secret and returnd the server proof.
     It concludes the exchange in valid state if successful.
     */
    func verifyProofs(_ clientEphemeralBytes: Data?, clientProofBytes: Data?) throws -> Data
}
