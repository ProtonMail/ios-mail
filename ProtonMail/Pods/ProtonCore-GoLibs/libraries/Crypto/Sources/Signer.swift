//
//  Signer.swift
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

/// signing
public enum Sign {
    
    /// sign data detached
    /// - Parameters:
    ///   - signingKey: signer
    ///   - plainData: raw data
    /// - Returns: armored signature
    public static func signDetached(signingKey: SigningKey, plainData: Data) throws -> ArmoredSignature {
        return try Crypto().signDetached(plainRaw: .right(plainData), signer: signingKey, trimTrailingSpaces: false)
    }

    /// sign string detached
    /// - Parameters:
    ///   - signingKey: signer
    ///   - plainText: plain text
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before signing.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    /// - Returns: armored signature
    public static func signDetached(signingKey: SigningKey, plainText: String, trimTrailingSpaces: Bool = true) throws -> ArmoredSignature {
        return try Crypto().signDetached(plainRaw: .left(plainText), signer: signingKey, trimTrailingSpaces: trimTrailingSpaces)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before verifying.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainText: String, verifierKey: ArmoredKey, verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .left(signature), verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before verifying.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainText: String,
                                      verifierKey: ArmoredKey, verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .right(unArmoredSignature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before verifying.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainText: String, verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .left(signature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before verifying.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainText: String,
                                      verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .right(unArmoredSignature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainData: Data, verifierKeys: [ArmoredKey], verifyTime: Int64 = 0) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .left(signature), verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: false)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainData: Data,
                                      verifierKeys: [ArmoredKey], verifyTime: Int64 = 0) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .right(unArmoredSignature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: false)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainData: Data, verifierKey: ArmoredKey, verifyTime: Int64 = 0) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .left(signature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: false)
    }
    
    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainData: plain data source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainData: Data,
                                      verifierKey: ArmoredKey, verifyTime: Int64 = 0) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .right(unArmoredSignature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: false)
    }
    
    public static func signStream(publicKey: ArmoredKey, signerKey: SigningKey, plainFile: URL) throws -> ArmoredSignature {
        return try Crypto().signStream(publicKey: publicKey, signerKey: signerKey, plainFile: plainFile)
    }
}
