//
//  OpenPGP+Extension.swift
//  ProtonCore-Features - Created on 22.05.2018.
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
import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel

extension Data {

    @available(*, deprecated, renamed: "getSession")
    func getSessionFromPubKeyPackageNonOptional(_ passphrase: String, privKeys: [Data]) throws -> SymmetricKey {
        return try Crypto().getSessionNonOptional(keyPacket: self, privateKeys: privKeys, passphrase: passphrase)
    }

    @available(*, deprecated, renamed: "getSession")
    func getSessionFromPubKeyPackageNonOptional(addrPrivKey: String, passphrase: String) throws -> SymmetricKey {
        return try Crypto().getSessionNonOptional(keyPacket: self, privateKey: addrPrivKey, passphrase: passphrase)
    }

    /// added after crypto refactor
    func getSession(addrPrivKey: String, passphrase: String) throws -> SessionKey {
        let decryptionKey = DecryptionKey.init(privateKey: ArmoredKey.init(value: addrPrivKey),
                                               passphrase: Passphrase.init(value: passphrase))
        return try Decryptor.decryptSessionKey(decryptionKeys: [decryptionKey], keyPacket: self)
    }

}
