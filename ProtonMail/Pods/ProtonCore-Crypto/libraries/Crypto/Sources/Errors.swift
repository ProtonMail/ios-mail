//
//  Errors.swift
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

public enum CryptoError: Error {
    case couldNotCreateKey
    case couldNotCreateKeyRing
    case couldNotCreateRandomToken
    
    case couldNotSignDetached
    
    case attachmentCouldNotBeEncrypted
    case attachmentCouldNotBeDecrypted
    
    case messageCouldNotBeEncrypted
    case messageCouldNotBeDecrypted
    
    case messageCouldNotBeDecryptedWithExplicitVerification
    
    case sessionKeyCouldNotBeDecrypted
    case sessionKeyCouldNotBeEncrypted
    
    case splitMessageDataNil
    case splitMessageKeyNil
    
    case signerNotPrivateKey
    
    case streamCleartextFileHasNoSize
    
    case emptyResult
    
    case outputFileAlreadyExists
    
    case tokenDecryptionFailed
    case tokenSignatureVerificationFailed
    
    case decryptAndVerifyFailed
    
    case emptyAddressKeys
}

public enum CryptoKeyError: Error {
    case noKeyCouldBeUnlocked(errors: [Error])
}

public enum ArmoredError: Error {
    case noKeyPacket
    case noDataPacket
}

public enum SessionError: Error {
    case unSupportedAlgorithm
    case emptyKey
}

public enum SignError: Error {
    case invalidPublicKey
    case invalidPrivateKey
    
    case invalidSigningKey
}

public struct SignatureVerifyError: Error {
    public let message: String?
}
