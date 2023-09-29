//
//  CryptoGoMethods.swift
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

public enum CryptoGoMethodsImplementation: CryptoGoMethods {


    case instance

    // initializers for types
    /// creates a new key from the first key in the unarmored binary data.
    public func CryptoKey(_ binKeys: Data?) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        GoLibs.CryptoKey(binKeys)
    }

    public func CryptoKey(fromArmored armored: String?) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        GoLibs.CryptoKey(fromArmored: armored)
    }


    public func CryptoNewKeyRing(_ key: ProtonCore_CryptoGoInterface.CryptoKey?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKeyRing? {
        GoLibs.CryptoNewKeyRing(key?.toGoLibsType, error)
    }

    public func CryptoPGPMessage(fromArmored armored: String?) -> ProtonCore_CryptoGoInterface.CryptoPGPMessage? {
        GoLibs.CryptoPGPMessage(fromArmored: armored)
    }

    public func CryptoPGPSplitMessage(_ keyPacket: Data?, dataPacket: Data?) -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage? {
        GoLibs.CryptoPGPSplitMessage(keyPacket, dataPacket: dataPacket)
    }

    public func CryptoPGPSplitMessage(fromArmored encrypted: String?) -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage? {
        GoLibs.CryptoPGPSplitMessage(fromArmored: encrypted)
    }

    public func CryptoPlainMessage(_ data: Data?) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.CryptoPlainMessage(data)
    }

    public func CryptoPlainMessage(from text: String?) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.CryptoPlainMessage(from: text)
    }

    public func CryptoKeyRing(_ key: ProtonCore_CryptoGoInterface.CryptoKey?) -> ProtonCore_CryptoGoInterface.CryptoKeyRing? {
        GoLibs.CryptoKeyRing(key?.toGoLibsType)
    }

    public func CryptoPGPSignature(fromArmored armored: String?) -> ProtonCore_CryptoGoInterface.CryptoPGPSignature? {
        GoLibs.CryptoPGPSignature(fromArmored: armored)
    }

    public func HelperGo2IOSReader(_ reader: ProtonCore_CryptoGoInterface.CryptoReaderProtocol?) -> ProtonCore_CryptoGoInterface.HelperGo2IOSReader? {
        GoLibs.HelperGo2IOSReader(reader?.toGoLibsType)
    }

    public func HelperMobileReadResult(_ n: Int, eof: Bool, data: Data?) -> ProtonCore_CryptoGoInterface.HelperMobileReadResult? {
        GoLibs.HelperMobileReadResult(n, eof: eof, data: data)
    }

    public func HelperMobile2GoReader(_ reader: ProtonCore_CryptoGoInterface.HelperMobileReaderProtocol?) -> ProtonCore_CryptoGoInterface.HelperMobile2GoReader? {
        GoLibs.HelperMobile2GoReader(reader?.toGoLibsType)
    }

    public func HelperMobile2GoWriter(_ writer: ProtonCore_CryptoGoInterface.CryptoWriterProtocol?) -> ProtonCore_CryptoGoInterface.HelperMobile2GoWriter? {
        GoLibs.HelperMobile2GoWriter(writer?.toGoLibsType)
    }

    public func HelperMobile2GoWriterWithSHA256(_ writer: ProtonCore_CryptoGoInterface.CryptoWriterProtocol?) -> ProtonCore_CryptoGoInterface.HelperMobile2GoWriterWithSHA256? {
        GoLibs.HelperMobile2GoWriterWithSHA256(writer?.toGoLibsType)
    }

    public func CryptoSigningContext(_ value: String?, isCritical: Bool) -> ProtonCore_CryptoGoInterface.CryptoSigningContext? {
        GoLibs.CryptoSigningContext(value, isCritical: isCritical)
    }

    public func CryptoVerificationContext(_ value: String?, isRequired: Bool, requiredAfter: Int64) -> ProtonCore_CryptoGoInterface.CryptoVerificationContext? {
        GoLibs.CryptoVerificationContext(value, isRequired: isRequired, requiredAfter: requiredAfter)
    }

    public func SrpAuth(_ version: Int, _ username: String?, _ password: Data?, _ b64salt: String?, _ signedModulus: String?, _ serverEphemeral: String?) -> ProtonCore_CryptoGoInterface.SrpAuth? {
        GoLibs.SrpAuth(version, username: username, password: password, b64salt: b64salt, signedModulus: signedModulus, serverEphemeral: serverEphemeral)
    }
    
    public func SrpNewAuth(_ version: Int, _ username: String?, _ password: Data?, _ b64salt: String?, _ signedModulus: String?, _ serverEphemeral: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.SrpAuth? {
        GoLibs.SrpNewAuth(version, username, password, b64salt, signedModulus, serverEphemeral, error)
    }
    
    public func SrpNewAuthForVerifier(_ password: Data?, _ signedModulus: String?, _ rawSalt: Data?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.SrpAuth? {
        GoLibs.SrpNewAuthForVerifier(password, signedModulus, rawSalt, error)
    }
    
    public func SrpRandomBits(_ bits: Int, _ error: NSErrorPointer) -> Data? {
        GoLibs.SrpRandomBits(bits, error)
    }

    public func SrpRandomBytes(_ byes: Int, _ error: NSErrorPointer) -> Data? {
        GoLibs.SrpRandomBytes(byes, error)
    }

    public func SrpProofs() -> ProtonCore_CryptoGoInterface.SrpProofs {
        GoLibs.SrpProofs()
    }

    public func SrpNewServerFromSigned(_ signedModulus: String?, _ verifier: Data?, _ bitLength: Int, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.SrpServer? {
        let value: GoLibs.SrpServer? =  GoLibs.SrpNewServerFromSigned(signedModulus, verifier, bitLength, error)
        return value
    }

    // global functions

    public func ArmorUnarmor(_ input: String?, _ error: NSErrorPointer) -> Data? {
        GoLibs.ArmorUnarmor(input, error)
    }

    public func ArmorArmorKey(_ input: Data?, _ error: NSErrorPointer) -> String {
        GoLibs.ArmorArmorKey(input, error)
    }
    
    public func ArmorArmorWithType(_ input: Data?, _ armorType: String?, _ error: NSErrorPointer) -> String {
        GoLibs.ArmorArmorWithType(input, armorType, error)
    }

    public func CryptoNewKey(_ binKeys: Data?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        GoLibs.CryptoNewKey(binKeys, error)
    }

    public func CryptoNewKeyFromArmored(_ armored: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        GoLibs.CryptoNewKeyFromArmored(armored, error)
    }

    public func CryptoGenerateKey(_ name: String?, _ email: String?, _ keyType: String?, _ bits: Int, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoKey? {
        GoLibs.CryptoGenerateKey(name, email, keyType, bits, error)
    }
    
    public func CryptoGenerateSessionKey(_ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoSessionKey? {
        GoLibs.CryptoGenerateSessionKey(error)
    }

    public func CryptoGenerateSessionKeyAlgo(_ algo: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoSessionKey? {
        GoLibs.CryptoGenerateSessionKeyAlgo(algo, error)
    }

    public func CryptoGetUnixTime() -> Int64 {
        GoLibs.CryptoGetUnixTime()
    }

    public func CryptoUpdateTime(_ newTime: Int64) {
        GoLibs.CryptoUpdateTime(newTime)
    }

    public func CryptoSetKeyGenerationOffset(_ offset: Int64) {
        GoLibs.CryptoSetKeyGenerationOffset(offset)
    }

    public func HelperFreeOSMemory() {
        GoLibs.HelperFreeOSMemory()
    }

    public func HelperGenerateKey(_ name: String?, _ email: String?, _ passphrase: Data?, _ keyType: String?, _ bits: Int, _ error: NSErrorPointer) -> String {
        GoLibs.HelperGenerateKey(name, email, passphrase, keyType, bits, error)
    }

    public func HelperDecryptMessageArmored(_ privateKey: String?, _ passphrase: Data?, _ ciphertext: String?, _ error: NSErrorPointer) -> String {
        GoLibs.HelperDecryptMessageArmored(privateKey, passphrase, ciphertext, error)
    }

    public func HelperDecryptSessionKey(_ privateKey: String?, _ passphrase: Data?, _ encryptedSessionKey: Data?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoSessionKey? {
        GoLibs.HelperDecryptSessionKey(privateKey, passphrase, encryptedSessionKey, error)
    }

    public func HelperDecryptAttachment(_ keyPacket: Data?, _ dataPacket: Data?, _ keyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.HelperDecryptAttachment(keyPacket, dataPacket, keyRing?.toGoLibsType, error)
    }

    public func HelperDecryptExplicitVerify(_ pgpMessage: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, _ privateKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ publicKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ verifyTime: Int64, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.HelperExplicitVerifyMessage? {
        GoLibs.HelperDecryptExplicitVerify(pgpMessage?.toGoLibsType,
                                           privateKeyRing?.toGoLibsType,
                                           publicKeyRing?.toGoLibsType,
                                           verifyTime,
                                           error)
    }

    public func HelperDecryptExplicitVerifyWithContext(_ pgpMessage: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, _ privateKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ publicKeyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ verifyTime: Int64, _ verificationContext: ProtonCore_CryptoGoInterface.CryptoVerificationContext?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.HelperExplicitVerifyMessage? {
        GoLibs.HelperDecryptExplicitVerifyWithContext(
            pgpMessage?.toGoLibsType,
            privateKeyRing?.toGoLibsType,
            publicKeyRing?.toGoLibsType,
            verifyTime,
            verificationContext?.toGoLibsType,
            error
        )
    }

    public func HelperEncryptSessionKey(_ publicKey: String?, _ sessionKey: ProtonCore_CryptoGoInterface.CryptoSessionKey?, _ error: NSErrorPointer) -> Data? {
        GoLibs.HelperEncryptSessionKey(publicKey, sessionKey?.toGoLibsType, error)
    }

    public func HelperEncryptMessageArmored(_ key: String?, _ plaintext: String?, _ error: NSErrorPointer) -> String {
        GoLibs.HelperEncryptMessageArmored(key, plaintext, error)
    }

    public func HelperEncryptSignMessageArmored(_ publicKey: String?, _ privateKey: String?, _ passphrase: Data?, _ plaintext: String?, _ error: NSErrorPointer) -> String {
        GoLibs.HelperEncryptSignMessageArmored(publicKey, privateKey, passphrase, plaintext, error)
    }

    public func HelperEncryptBinaryMessageArmored(_ key: String?, _ data: Data?, _ error: NSErrorPointer) -> String {
        GoLibs.HelperEncryptBinaryMessageArmored(key, data, error)
    }

    public func HelperEncryptAttachment(_ plainData: Data?, _ filename: String?, _ keyRing: ProtonCore_CryptoGoInterface.CryptoKeyRing?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage? {
        GoLibs.HelperEncryptAttachment(plainData, filename, keyRing?.toGoLibsType, error)
    }

    public func HelperUpdatePrivateKeyPassphrase(_ privateKey: String?, _ oldPassphrase: Data?, _ newPassphrase: Data?, _ error: NSErrorPointer) -> String {
        GoLibs.HelperUpdatePrivateKeyPassphrase(privateKey, oldPassphrase, newPassphrase, error)
    }

    public func HelperGetJsonSHA256Fingerprints(_ publicKey: String?, _ error: NSErrorPointer) -> Data? {
        GoLibs.HelperGetJsonSHA256Fingerprints(publicKey, error)
    }

    public func SrpMailboxPassword(_ password: Data?, _ salt: Data?, _ error: NSErrorPointer) -> Data? {
        GoLibs.SrpMailboxPassword(password, salt, error)
    }

    public func SrpArgon2PreimageChallenge(_ b64Challenge: String?, _ deadlineUnixMilli: Int64, _ error: NSErrorPointer) -> String {
        GoLibs.SrpArgon2PreimageChallenge(b64Challenge, deadlineUnixMilli, error)
    }

    public func SrpECDLPChallenge(_ b64Challenge: String?, _ deadlineUnixMilli: Int64, _ error: NSErrorPointer) -> String {
        GoLibs.SrpECDLPChallenge(b64Challenge, deadlineUnixMilli, error)
    }
    
    public func SubtleDecryptWithoutIntegrity(_ key: Data?, _ input: Data?, _ iv: Data?, _ error: NSErrorPointer) -> Data? {
        GoLibs.SubtleDecryptWithoutIntegrity(key, input, iv, error)
    }
    
    public func SubtleDeriveKey(_ password: String?, _ salt: Data?, _ n: Int, _ error: NSErrorPointer) -> Data? {
        GoLibs.SubtleDeriveKey(password, salt, n, error)
    }

    public func SubtleEncryptWithoutIntegrity(_ key: Data?, _ input: Data?, _ iv: Data?, _ error: NSErrorPointer) -> Data? {
        GoLibs.SubtleEncryptWithoutIntegrity(key, input, iv, error)
    }

    public func CryptoRandomToken(_ size: Int, _ error: NSErrorPointer) -> Data? {
        GoLibs.CryptoRandomToken(size, error)
    }

    public func CryptoNewPGPMessage(_ data: Data?) -> ProtonCore_CryptoGoInterface.CryptoPGPMessage? {
        GoLibs.CryptoNewPGPMessage(data)
    }

    public func CryptoNewPGPMessageFromArmored(_ armored: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPGPMessage? {
        GoLibs.CryptoNewPGPMessageFromArmored(armored, error)
    }

    public func CryptoNewPGPSplitMessage(_ keyPacket: Data?, _ dataPacket: Data?) -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage? {
        GoLibs.CryptoNewPGPSplitMessage(keyPacket, dataPacket)
    }

    public func CryptoNewPGPSplitMessageFromArmored(_ encrypted: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPGPSplitMessage? {
        GoLibs.CryptoNewPGPSplitMessageFromArmored(encrypted, error)
    }

    public func CryptoNewPGPSignature(_ data: Data?) -> ProtonCore_CryptoGoInterface.CryptoPGPSignature? {
        GoLibs.CryptoNewPGPSignature(data)
    }

    public func CryptoNewPGPSignatureFromArmored(_ armored: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPGPSignature? {
        GoLibs.CryptoNewPGPSignatureFromArmored(armored, error)
    }

    public func CryptoNewPlainMessage(_ data: Data?) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.CryptoNewPlainMessage(data)
    }

    public func CryptoNewPlainMessageFromString(_ text: String?) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.CryptoNewPlainMessageFromString(text)
    }

    public func CryptoNewClearTextMessageFromArmored(_ signedMessage: String?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoClearTextMessage? {
        GoLibs.CryptoNewClearTextMessageFromArmored(signedMessage, error)
    }

    public func CryptoNewSessionKeyFromToken(_ token: Data?, _ algo: String?) -> ProtonCore_CryptoGoInterface.CryptoSessionKey? {
        GoLibs.CryptoNewSessionKeyFromToken(token, algo)
    }

    public func CryptoEncryptMessageWithPassword(_ message: ProtonCore_CryptoGoInterface.CryptoPlainMessage?, _ password: Data?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPGPMessage? {
        GoLibs.CryptoEncryptMessageWithPassword(message?.toGoLibsType, password, error)
    }

    public func CryptoDecryptMessageWithPassword(_ message: ProtonCore_CryptoGoInterface.CryptoPGPMessage?, _ password: Data?, _ error: NSErrorPointer) -> ProtonCore_CryptoGoInterface.CryptoPlainMessage? {
        GoLibs.CryptoDecryptMessageWithPassword(message?.toGoLibsType, password, error)
    }

    public func CryptoEncryptSessionKeyWithPassword(_ sk: ProtonCore_CryptoGoInterface.CryptoSessionKey?, _ password: Data?, _ error: NSErrorPointer) -> Data? {
        GoLibs.CryptoEncryptSessionKeyWithPassword(sk?.toGoLibsType, password, error)
    }
}
