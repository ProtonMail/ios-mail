// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import ProtonCoreDataModel
import ProtonCoreCrypto

public struct AddressKeyPackage {
    public let activeKeys: [AddressKey_v2]
    public let activePrimaryKey: AddressKey_v2
    public let passphraseInfo: PassphraseInfo

    public struct PassphraseInfo {
        public let user: User
        public let userPassphrase: String

        public init(user: User, userPassphrase: String) {
            self.user = user
            self.userPassphrase = userPassphrase
        }
    }

    public init?(keys: [AddressKey_v2], passphraseInfo: PassphraseInfo) {
        let activeKeys = keys.filter(\.active)

        guard let activePrimaryKey = activeKeys.first(where: \.primary) else {
            return nil
        }

        self.activeKeys = activeKeys
        self.activePrimaryKey = activePrimaryKey
        self.passphraseInfo = passphraseInfo
    }
}

public extension AddressKeyPackage {

    func decryptionKeys() throws -> [DecryptionKey] {
        try activeKeys.map { addressKey in
            .init(
                privateKey: .init(value: addressKey.privateKey),
                passphrase: try passphrase(for: addressKey)
            )
        }
    }

    func primaryDecryptionKey() throws -> DecryptionKey {
        .init(
            privateKey: .init(value: activePrimaryKey.privateKey),
            passphrase: try passphrase(for: activePrimaryKey)
        )
    }

    private func passphrase(for addressKey: AddressKey_v2) throws -> Passphrase {
        let key = Key(codable: addressKey)
        let passphrase: Passphrase = try key.passphrase(
            userKeys: passphraseInfo.user.keys,
            mailboxPassphrase: passphraseInfo.userPassphrase
        )

        return passphrase
    }

}
