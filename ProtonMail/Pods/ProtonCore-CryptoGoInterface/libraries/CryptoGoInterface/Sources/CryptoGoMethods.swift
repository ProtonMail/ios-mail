//
//  CryptoGoMethods.swift
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

public protocol CryptoGoMethods {
    var ConstantsAES256: String { get }
    
    // initializers
    func CryptoKey(_ binKeys: Data?) -> CryptoKey?
    func CryptoKey(fromArmored armored: String?) -> CryptoKey?
    func CryptoPGPMessage(fromArmored armored: String?) -> CryptoPGPMessage?
    func CryptoPGPSplitMessage(_ keyPacket: Data?, dataPacket: Data?) -> CryptoPGPSplitMessage?
    func CryptoPGPSplitMessage(fromArmored encrypted: String?) -> CryptoPGPSplitMessage?
    func CryptoPlainMessage(_ data: Data?) -> CryptoPlainMessage?
    func CryptoPlainMessage(from text: String?) -> CryptoPlainMessage?
    func CryptoKeyRing(_ key: CryptoKey?) -> CryptoKeyRing?
    func CryptoPGPSignature(fromArmored armored: String?) -> CryptoPGPSignature?

    func HelperGo2IOSReader(_ reader: CryptoReaderProtocol?) -> HelperGo2IOSReader?
    func HelperMobileReadResult(_ n: Int, eof: Bool, data: Data?) -> HelperMobileReadResult?
    func HelperMobile2GoReader(_ reader: HelperMobileReaderProtocol?) -> HelperMobile2GoReader?
    func HelperMobile2GoWriter(_ writer: CryptoWriterProtocol?) -> HelperMobile2GoWriter?
    func HelperMobile2GoWriterWithSHA256(_ writer: CryptoWriterProtocol?) -> HelperMobile2GoWriterWithSHA256?

    func CryptoSigningContext(_ value: String?, isCritical: Bool) -> CryptoSigningContext?
    func CryptoVerificationContext(_ value: String?, isRequired: Bool, requiredAfter: Int64) -> CryptoVerificationContext?

    func SrpAuth(_ version: Int, _ username: String?, _ password: Data?, _ b64salt: String?, _ signedModulus: String?, _ serverEphemeral: String?) -> SrpAuth?
    
    func SrpNewAuth(_ version: Int, _ username: String?, _ password: Data?, _ b64salt: String?, _ signedModulus: String?, _ serverEphemeral: String?, _ error: NSErrorPointer) -> SrpAuth?
    
    func SrpNewAuthForVerifier(_ password: Data?, _ signedModulus: String?, _ rawSalt: Data?, _ error: NSErrorPointer) -> SrpAuth?
    
    func SrpRandomBits(_ bits: Int, _ error: NSErrorPointer) -> Data?

    func SrpRandomBytes(_ byes: Int, _ error: NSErrorPointer) -> Data?

    func SrpProofs() -> SrpProofs

    func SrpNewServerFromSigned(_ signedModulus: String?, _ verifier: Data?, _ bitLength: Int, _ error: NSErrorPointer) -> SrpServer?

    // functions
    func ArmorUnarmor(_ input: String?, _ error: NSErrorPointer) -> Data?
    func ArmorArmorKey(_ input: Data?, _ error: NSErrorPointer) -> String
    func ArmorArmorWithType(_ input: Data?, _ armorType: String?, _ error: NSErrorPointer) -> String

    func CryptoGenerateKey(_ name: String?, _ email: String?, _ keyType: String?, _ bits: Int, _ error: NSErrorPointer) -> CryptoKey?

    func CryptoNewKey(_ binKeys: Data?, _ error: NSErrorPointer) -> CryptoKey?
    func CryptoNewKeyFromArmored(_ armored: String?, _ error: NSErrorPointer) -> CryptoKey?

    func CryptoGenerateSessionKey(_ error: NSErrorPointer) -> CryptoSessionKey?
    func CryptoGenerateSessionKeyAlgo(_ algo: String?, _ error: NSErrorPointer) -> CryptoSessionKey?

    func CryptoGetUnixTime() -> Int64
    func CryptoUpdateTime(_ newTime: Int64)
    func CryptoSetKeyGenerationOffset(_ offset: Int64)

    func HelperFreeOSMemory()
    func HelperGenerateKey(_ name: String?, _ email: String?, _ passphrase: Data?, _ keyType: String?, _ bits: Int, _ error: NSErrorPointer) -> String
    func HelperDecryptMessageArmored(_ privateKey: String?, _ passphrase: Data?, _ ciphertext: String?, _ error: NSErrorPointer) -> String
    func HelperDecryptSessionKey(_ privateKey: String?, _ passphrase: Data?, _ encryptedSessionKey: Data?, _ error: NSErrorPointer) -> CryptoSessionKey?
    func HelperDecryptSessionKeyExplicitVerify(_ dataPacket: Data?, _ sessionKey: CryptoSessionKey?, _ publicKeyRing: CryptoKeyRing?, _ verifyTime: Int64, _ error: NSErrorPointer) -> HelperExplicitVerifyMessage?
    func HelperDecryptAttachment(_ keyPacket: Data?, _ dataPacket: Data?, _ keyRing: CryptoKeyRing?, _ error: NSErrorPointer) -> CryptoPlainMessage?

    func HelperDecryptExplicitVerify(_ pgpMessage: CryptoPGPMessage?, _ privateKeyRing: CryptoKeyRing?, _ publicKeyRing: CryptoKeyRing?, _ verifyTime: Int64, _ error: NSErrorPointer) -> HelperExplicitVerifyMessage?

    func HelperDecryptExplicitVerifyWithContext(_ pgpMessage: CryptoPGPMessage?, _ privateKeyRing: CryptoKeyRing?, _ publicKeyRing: CryptoKeyRing?, _ verifyTime: Int64, _ verificationContext: CryptoVerificationContext?, _ error: NSErrorPointer) -> HelperExplicitVerifyMessage?

    func HelperEncryptSessionKey(_ publicKey: String?, _ sessionKey: CryptoSessionKey?, _ error: NSErrorPointer) -> Data?
    func HelperEncryptMessageArmored(_ key: String?, _ plaintext: String?, _ error: NSErrorPointer) -> String
    func HelperEncryptSignMessageArmored(_ publicKey: String?, _ privateKey: String?, _ passphrase: Data?, _ plaintext: String?, _ error: NSErrorPointer) -> String
    func HelperEncryptBinaryMessageArmored(_ key: String?, _ data: Data?, _ error: NSErrorPointer) -> String
    func HelperEncryptAttachment(_ plainData: Data?, _ filename: String?, _ keyRing: CryptoKeyRing?, _ error: NSErrorPointer) -> CryptoPGPSplitMessage?
    func HelperUpdatePrivateKeyPassphrase(_ privateKey: String?, _ oldPassphrase: Data?, _ newPassphrase: Data?, _ error: NSErrorPointer) -> String

    func HelperGetJsonSHA256Fingerprints(_ publicKey: String?, _ error: NSErrorPointer) -> Data?

    func SrpMailboxPassword(_ password: Data?, _ salt: Data?, _ error: NSErrorPointer) -> Data?
    func SrpArgon2PreimageChallenge(_ b64Challenge: String?, _ deadlineUnixMilli: Int64, _ error: NSErrorPointer) -> String
    func SrpECDLPChallenge(_ b64Challenge: String?, _ deadlineUnixMilli: Int64, _ error: NSErrorPointer) -> String
    
    func SubtleDecryptWithoutIntegrity(_ key: Data?, _ input: Data?, _ iv: Data?, _ error: NSErrorPointer) -> Data?
    
    func SubtleDeriveKey(_ password: String?, _ salt: Data?, _ n: Int, _ error: NSErrorPointer) -> Data?

    func SubtleEncryptWithoutIntegrity(_ key: Data?, _ input: Data?, _ iv: Data?, _ error: NSErrorPointer) -> Data?

    func CryptoRandomToken(_ size: Int, _ error: NSErrorPointer) -> Data?

    func CryptoNewKeyRing(_ key: CryptoKey?, _ error: NSErrorPointer) -> CryptoKeyRing?

    func CryptoNewPGPMessage(_ data: Data?) -> CryptoPGPMessage?
    func CryptoNewPGPMessageFromArmored(_ armored: String?, _ error: NSErrorPointer) -> CryptoPGPMessage?

    func CryptoNewPGPSplitMessage(_ keyPacket: Data?, _ dataPacket: Data?) -> CryptoPGPSplitMessage?
    func CryptoNewPGPSplitMessageFromArmored(_ encrypted: String?, _ error: NSErrorPointer) -> CryptoPGPSplitMessage?

    func CryptoNewPGPSignature(_ data: Data?) -> CryptoPGPSignature?
    func CryptoNewPGPSignatureFromArmored(_ armored: String?, _ error: NSErrorPointer) -> CryptoPGPSignature?

    func CryptoNewPlainMessage(_ data: Data?) -> CryptoPlainMessage?
    func CryptoNewPlainMessageFromString(_ text: String?) -> CryptoPlainMessage?

    func CryptoNewClearTextMessageFromArmored(_ signedMessage: String?, _ error: NSErrorPointer) -> CryptoClearTextMessage?

    func CryptoNewSessionKeyFromToken(_ token: Data?, _ algo: String?) -> CryptoSessionKey?

    func CryptoEncryptMessageWithPassword(_ message: CryptoPlainMessage?, _ password: Data?, _ error: NSErrorPointer) -> CryptoPGPMessage?
    func CryptoDecryptMessageWithPassword(_ message: CryptoPGPMessage?, _ password: Data?, _ error: NSErrorPointer) -> CryptoPlainMessage?

    func CryptoEncryptSessionKeyWithPassword(_ sk: CryptoSessionKey?, _ password: Data?, _ error: NSErrorPointer) -> Data?
}
