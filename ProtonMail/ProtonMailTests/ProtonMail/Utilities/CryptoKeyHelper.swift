// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import GoLibs
import ProtonCore_Authentication_KeyGeneration
import ProtonCore_Crypto
import ProtonCore_DataModel

enum CryptoKeyHelper {

    /// Creates a public/private key pair with a passphrase that follows a 64 byte hex string format. The same
    /// format used in the mail app.
    static func makeKeyPair() throws -> (passphrase: String, publicKey: String, privateKey: String) {
        let passphrase = PasswordHash.genAddrPassphrase()
        let username = UUID().uuidString
        let domain = "protonmail.com"
        let email = "\(username)@\(domain)"
        let keyType = "x25519"
        var error: NSError?

        guard let unlockedKey = CryptoGenerateKey(username, email, keyType, 0, &error) else {
            throw NSError()
        }
        let cryptoKey = try unlockedKey.lock(passphrase.value.data(using: .utf8))
        unlockedKey.clearPrivateParams()
        let publicKey = cryptoKey.getArmoredPublicKey(&error)
        if let concreteError = error {
            throw concreteError
        }
        let privateKey = cryptoKey.armor(&error)
        if let concreteError = error {
            throw concreteError
        }
        return (passphrase.value, publicKey, privateKey)
    }

    /// Creates a public/private Key object, using the user key the same way Address keys are generated in the app.
    static func makeAddressKey(
        userKey: (passphrase: String, publicKey: String, privateKey: String)
    ) -> Key {
        let senderAddressKey = try! CryptoKeyHelper.makeKeyPair()
        let senderEncryptedPassphrase = try! Encryptor.encrypt(
            publicKey: ArmoredKey(value: userKey.publicKey),
            cleartext: senderAddressKey.passphrase
        )
        let senderPassphraseSignature = try! Sign.signDetached(
            signingKey: SigningKey(
                privateKey: Armored(value: userKey.privateKey),
                passphrase: Password(value: userKey.passphrase)
            ),
            plainText: senderAddressKey.passphrase
        )
        return Key(
            keyID: UUID().uuidString,
            privateKey: senderAddressKey.privateKey,
            token: senderEncryptedPassphrase.value,
            signature: senderPassphraseSignature.value
        )
    }
}
