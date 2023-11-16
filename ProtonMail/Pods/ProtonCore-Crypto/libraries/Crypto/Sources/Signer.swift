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
import ProtonCoreCryptoGoInterface
import ProtonCoreUtilities

/// signing
public enum Sign {

    /// sign data detached
    /// - Parameters:
    ///   - signingKey: signer
    ///   - plainData: raw data
    ///   - signatureContext: optional context, which is added to the signature as notation data.
    /// - Returns: armored signature
    public static func signDetached(signingKey: SigningKey, plainData: Data, signatureContext: SignatureContext? = nil) throws -> ArmoredSignature {
        return try Crypto().signDetached(plainRaw: .right(plainData), signer: signingKey, trimTrailingSpaces: false, signatureContext: signatureContext)
    }

    /// sign string detached
    /// - Parameters:
    ///   - signingKey: signer
    ///   - plainText: plain text
    ///   - trimTrailingSpaces: If true, line ends will be trimmed of all trailing spaces and tabs, before signing.
    ///     This is sometimes needed because it's expected by a standard, or to keep compatibility
    ///     with old signatures, as this used to be the default behavior.
    ///   - signatureContext: optional context, which is added to the signature as notation data.
    /// - Returns: armored signature
    public static func signDetached(signingKey: SigningKey, plainText: String, trimTrailingSpaces: Bool = true, signatureContext: SignatureContext? = nil) throws -> ArmoredSignature {
        return try Crypto().signDetached(plainRaw: .left(plainText), signer: signingKey, trimTrailingSpaces: trimTrailingSpaces, signatureContext: signatureContext)
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
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainText: String, verifierKey: ArmoredKey, verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .left(signature), verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces, verificationContext: verificationContext)
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
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainText: String,
                                      verifierKey: ArmoredKey, verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .right(unArmoredSignature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces, verificationContext: verificationContext)
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
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainText: String, verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .left(signature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces, verificationContext: verificationContext)
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
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainText: String,
                                      verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, trimTrailingSpaces: Bool = true, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .left(plainText), signature: .right(unArmoredSignature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: trimTrailingSpaces, verificationContext: verificationContext)
    }

    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainData: Data, verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .left(signature), verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: false, verificationContext: verificationContext)
    }

    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainData: Data,
                                      verifierKeys: [ArmoredKey], verifyTime: Int64 = 0, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .right(unArmoredSignature),
                                           verifiers: verifierKeys, verifyTime: verifyTime, trimTrailingSpaces: false, verificationContext: verificationContext)
    }

    /// verify detached signature
    /// - Parameters:
    ///   - signature: signature
    ///   - plainText: plain source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(signature: ArmoredSignature, plainData: Data, verifierKey: ArmoredKey, verifyTime: Int64 = 0, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .left(signature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: false, verificationContext: verificationContext)
    }

    /// verify detached signature
    /// - Parameters:
    ///   - unArmoredSignature: raw signature
    ///   - plainData: plain data source to verify
    ///   - verifierKey: verifier
    ///   - verifyTime: verify time
    ///   - verificationContext: optional context, which can be used to enforce the signature was created with the right context.
    /// - Returns: true / false
    public static func verifyDetached(unArmoredSignature: UnArmoredSignature, plainData: Data,
                                      verifierKey: ArmoredKey, verifyTime: Int64 = 0, verificationContext: VerificationContext? = nil) throws -> Bool {
        return try Crypto().verifyDetached(input: .right(plainData), signature: .right(unArmoredSignature),
                                           verifier: verifierKey, verifyTime: verifyTime, trimTrailingSpaces: false, verificationContext: verificationContext)
    }

    /// Sign file using the streaming api, and encrypt the detached signature.
    /// - Parameters:
    ///   - publicKey: key used to encrypt the detached signature
    ///   - signingKey: signer
    ///   - plainFile: URL to the file to sign
    ///   - signatureContext: optional context, which is added to the signature as notation data.
    /// - Returns: armored signature
    public static func signStream(publicKey: ArmoredKey, signerKey: SigningKey, plainFile: URL, signatureContext: SignatureContext? = nil) throws -> ArmoredSignature {
        return try Crypto().signStream(publicKey: publicKey, signerKey: signerKey, plainFile: plainFile, signatureContext: signatureContext)
    }
}
