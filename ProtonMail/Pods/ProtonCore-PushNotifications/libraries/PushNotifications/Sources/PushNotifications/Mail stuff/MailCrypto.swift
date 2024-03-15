//
//  Crypto.swift
//  Proton Mail - Created on 9/11/19.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CryptoKit
import ProtonCoreDataModel

import ProtonCoreCryptoGoInterface
import ProtonCoreLog
import ProtonCoreCrypto

/// Helper
class MailCrypto {

    enum CryptoError: Error {
        case failedGeneratingKeypair(Error?)
        case decryptionFailed
    }

    // MARK: - static

    static func generateRandomKeyPair() throws -> (passphrase: String, publicKey: String, privateKey: String) {
        let passphrase = UUID().uuidString
        let username = UUID().uuidString
        let domain = "protonmail.com"
        let email = "\(username)@\(domain)"
        let keyType = "x25519"
        var error: NSError?

        guard let unlockedKey = CryptoGo.CryptoGenerateKey(username, email, keyType, 0, &error) else {
            throw CryptoError.failedGeneratingKeypair(error)
        }

        let cryptoKey = try unlockedKey.lock(passphrase.data(using: .utf8))
        unlockedKey.clearPrivateParams()

        let publicKey = cryptoKey.getArmoredPublicKey(&error)
        if let concreteError = error {
            throw CryptoError.failedGeneratingKeypair(concreteError)
        }
        let privateKey = cryptoKey.armor(&error)
        if let concreteError = error {
            throw CryptoError.failedGeneratingKeypair(concreteError)
        }

        return (passphrase, publicKey, privateKey)
    }
}
