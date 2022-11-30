//
//  OpenPGPExtension.swift
//  Proton Mail
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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel

// MARK: - OpenPGP String extension

extension String {
    func encrypt(withKey key: Key, userKeys: [ArmoredKey], mailbox_pwd: Passphrase) throws -> String {
        let armoredMessage: ArmoredMessage = try encrypt(withKey: key, userKeys: userKeys, mailbox_pwd: mailbox_pwd)
        return armoredMessage.value
    }

    private func encrypt(withKey key: Key, userKeys: [ArmoredKey], mailbox_pwd: Passphrase) throws -> ArmoredMessage {
        let addressKeyPassphrase = try key.passphrase(userPrivateKeys: userKeys, mailboxPassphrase: mailbox_pwd)

        let signerKey = SigningKey(
            privateKey: ArmoredKey(value: key.privateKey),
            passphrase: addressKeyPassphrase
        )

        return try Encryptor.encrypt(
            publicKey: ArmoredKey(value: key.publicKey),
            cleartext: self,
            signerKey: signerKey
        )
    }
}
