//
//  Encryptor.swift
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import GoLibs
import ProtonCore_Utilities

public enum Encryptor {
    
    /// encrypt a clear text with a public key. signer is optional
    /// - Parameters:
    ///   - publicKey: armored public to encrypt text
    ///   - cleartext: plaintext string
    ///   - signerKey: optional signer.  if not nil. will try to sign the message with this key
    /// - Returns: Armored encrypted message
    public static func encrypt(publicKey: ArmoredKey, cleartext: String, signerKey: SigningKey? = nil) throws -> ArmoredMessage {
        return try Crypto().encryptAndSign(plainRaw: Either.left(cleartext), publicKey: publicKey, signingKey: signerKey)
    }
    
    /// encrypt a raw session key with recipent's public key.
    /// - Parameters:
    ///   - publicKey: armored public key
    ///   - sessionKey: raw session key object
    /// - Returns: encrypted session(raw key packet) usually is Data. this func return based64 encded string
    public static func encryptSession(publicKey: ArmoredKey, sessionKey: SessionKey) throws -> Based64String {
        return try Crypto().encryptSessionKey(publicKey: publicKey, sessionKey: sessionKey)
    }
    
    /// encrypt a clear data with a public key. signer is optional
    /// - Parameters:
    ///   - publicKey: armored public to encrypt text
    ///   - cleartext: raw data
    ///   - signerKey: optional signer.  if not nil. will try to sign the message with this key
    /// - Returns: Armored encrypted message
    public static func encrypt(publicKey: ArmoredKey, clearData: Data, signerKey: SigningKey? = nil) throws -> ArmoredMessage {
        return try Crypto().encryptAndSign(plainRaw: Either.right(clearData), publicKey: publicKey, signingKey: signerKey)
    }
    
    /// encrypt a clear data with a public key. signer is optional. this func usually used when encrypt some blobs.
    ///  for saving time splited packet key packet can reencrypt by other keys very cheap.
    /// - Parameters:
    ///   - publicKey: armored public to encrypt text
    ///   - clearData: raw data
    ///   - signerKey: optional signer.  if not nil. will try to sign the message with this key
    /// - Returns: spit packet. inclide datapacket and keypacket
    public static func encryptSplit(publicKey: ArmoredKey, clearData: Data, signerKey: SigningKey? = nil) throws -> SplitPacket {
        return try Crypto().encryptAndSign(plainRaw: Either.right(clearData), publicKey: publicKey, signingKey: signerKey)
    }
    
    // swiftlint:disable function_parameter_count
    /// streaming encryption
    public static func encryptStreamHash(nodeKey: ArmoredKey, nodePassphase: Passphrase,
                                         contentKeyPacket: Data,
                                         clearFile: URL, cyphertextFile: URL,
                                         chunkSize: Int) throws -> Data {
        // prepare files
        if FileManager.default.fileExists(atPath: cyphertextFile.path) {
            try FileManager.default.removeItem(at: cyphertextFile)
        }
        FileManager.default.createFile(atPath: cyphertextFile.path, contents: Data(), attributes: nil)
        
        let readFileHandle = try FileHandle(forReadingFrom: clearFile)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cyphertextFile)
        defer { writeFileHandle.closeFile() }
        
        guard let size = try FileManager.default.attributesOfItem(atPath: clearFile.path)[.size] as? Int else {
            throw CryptoError.streamCleartextFileHasNoSize
        }
        // cryptography
        var error: NSError?
        let sessionKey = HelperDecryptSessionKey(nodeKey.value, nodePassphase.data, contentKeyPacket, &error)
        guard error == nil else { throw error! }
        
        let hash = try Crypto().encryptStreamRetSha256(sessionKey!, nil,
                                                       readFileHandle, writeFileHandle,
                                                       size, chunkSize)
        return hash
    }
    
    public static func encryptStream(publicKey: ArmoredKey,
                                     clearFile: URL, cyphertextFile: URL,
                                     chunkSize: Int) throws -> Data {
        // prepare files
        if FileManager.default.fileExists(atPath: cyphertextFile.path) {
            try FileManager.default.removeItem(at: cyphertextFile)
        }
        FileManager.default.createFile(atPath: cyphertextFile.path, contents: Data(), attributes: nil)
        
        let readFileHandle = try FileHandle(forReadingFrom: clearFile)
        defer { readFileHandle.closeFile() }
        let writeFileHandle = try FileHandle(forWritingTo: cyphertextFile)
        defer { writeFileHandle.closeFile() }
        
        guard let size = try FileManager.default.attributesOfItem(atPath: clearFile.path)[.size] as? Int else {
            throw CryptoError.streamCleartextFileHasNoSize
        }
        
        let keyPacket = try Crypto().encryptStream(publicKey,
                                                   readFileHandle,
                                                   writeFileHandle,
                                                   size,
                                                   chunkSize)
        return keyPacket
    }
    
    /// encrypt string with a token password.
    /// - Parameters:
    ///   - clearText: clear text
    ///   - token: could be any password
    /// - Returns: armored message
    public static func encrypt(clearText: String, token: TokenPassword) throws -> ArmoredMessage {
        return try Crypto().encrypt(input: .left(clearText), token: token)
    }
    
    /// encrypt data with a token password.
    /// - Parameters:
    ///   - clearText: clear text
    ///   - token: could be any password
    /// - Returns: armored message
    public static func encrypt(clearData: Data, token: TokenPassword) throws -> ArmoredMessage {
        return try Crypto().encrypt(input: .right(clearData), token: token)
    }
    
}
