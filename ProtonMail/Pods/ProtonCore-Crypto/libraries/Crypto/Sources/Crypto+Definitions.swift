//
//  Crypto+Definitions.swift
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
#if canImport(Crypto_VPN)
import Crypto_VPN
#elseif canImport(Crypto)
import Crypto
#endif

import ProtonCore_DataModel

internal func throwing<T>(operation: (inout NSError?) -> T) throws -> T {
    var error: NSError?
    let result = operation(&error)
    if let error = error { throw error }
    return result
}

public enum CryptoOperationError: Error {
    case nilResult
}

internal func throwingNotNil<T>(operation: (inout NSError?) -> T?) throws -> T {
    var error: NSError?
    let result = operation(&error)
    if let error = error { throw error }
    guard let result = result else {
        throw CryptoOperationError.nilResult
    }
    return result
}

public typealias KeyRing             = CryptoKeyRing
public typealias SplitMessage        = CryptoPGPSplitMessage
public typealias PlainMessage        = CryptoPlainMessage
public typealias PGPMessage          = CryptoPGPMessage
public typealias PGPSignature        = CryptoPGPSignature
public typealias AttachmentProcessor = CryptoAttachmentProcessor
public typealias SymmetricKey        = CryptoSessionKey

public typealias ExplicitVerifyMessage = HelperExplicitVerifyMessage
public typealias SignatureVerification = CryptoSignatureVerificationError

// used when you want to generate a session key and key packet.
//  session key is the generated session used to encrypt data and build data packet
//  contentKeyPacket is encrypted session by private key
//  contentKeyPacketSignature is signed session key by private key
public struct ContentKeys {
    public let sessionKey: String
    public let contentKeyPacket: String
    public let contentKeyPacketSignature: String
}

public struct EncryptedBlock {
    public var data, hash: Data
}

// this is the old `DecryptionAddress` replacement
public class DecryptionContext {
    public init(userKeys: [Key], addrKey: Key, passphrase: Passphrase) {
        self.userKeys = userKeys
        self.addrKey = addrKey
        self.passphrase = passphrase
    }
    
    public let userKeys: [Key]
    public let addrKey: Key
    public let passphrase: Passphrase
}

// packed private key and passphrase. used for encryption/decryption
public class DecryptionKey {
    public init(privateKey: ArmoredKey, passphrase: Passphrase) {
        self.privateKey = privateKey
        self.passphrase = passphrase
    }
    
    public let privateKey: ArmoredKey
    public let passphrase: Passphrase
    
    public var isEmpty: Bool {
        guard !self.privateKey.isEmpty else {
            return true
        }
        return false
    }
}

public typealias SigningKey = DecryptionKey
public typealias SigningContext = DecryptionContext
