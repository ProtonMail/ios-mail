// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreUtilities

class MessageDecrypterKeyFactory {
    private weak var userDataSource: UserDataSource?

    private var decryptionKeyRingCache: Atomic<[AddressID: CryptoKeyRing]> = Atomic([:])

    private var cachingEnabled = true {
        didSet {
            if !cachingEnabled {
                decryptionKeyRingCache.mutate { $0.removeAll() }
            }
        }
    }

    init(userDataSource: UserDataSource) {
        self.userDataSource = userDataSource
    }

    // Returns: the key ring and whether it was returned from cache
    func decryptionKeyRing(addressID: AddressID) throws -> (CryptoKeyRing, Bool) {
        if cachingEnabled, let cachedDecryptionKeyRing = decryptionKeyRingCache.transform({ $0[addressID] }) {
            return (cachedDecryptionKeyRing, true)
        } else {
            guard let dataSource = userDataSource else {
                throw MailCrypto.CryptoError.decryptionFailed
            }

            let addressKeys = getAddressKeys(for: addressID.rawValue)

            let decryptionKeys = MailCrypto.decryptionKeys(
                basedOn: addressKeys,
                mailboxPassword: dataSource.mailboxPassword,
                userKeys: dataSource.userInfo.userPrivateKeys
            )

            let decryptionKeyRing = try KeyRingBuilder().buildPrivateKeyRingUnlock(privateKeys: decryptionKeys)

            if cachingEnabled {
                decryptionKeyRingCache.mutate { $0[addressID] = decryptionKeyRing }
            }

            return (decryptionKeyRing, false)
        }
    }

    func removeKeyRingFromCache(addressID: AddressID) {
        decryptionKeyRingCache.mutate { $0[addressID] = nil }
    }

    func getAddressKeys(for addressID: String) -> [Key] {
        guard let userDataSource = userDataSource else {
            return []
        }

        let userInfo = userDataSource.userInfo

        return userInfo.getAllAddressKey(address_id: addressID) ?? userInfo.addressKeys
    }

    func setCaching(enabled: Bool) {
        cachingEnabled = enabled
    }
}
