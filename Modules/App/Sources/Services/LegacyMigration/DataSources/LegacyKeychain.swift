// Copyright (c) 2025 Proton Technologies AG
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
import InboxKeychain

final class LegacyKeychain: Keychain {
    enum Key: String {
        case biometricsProtectedMainKey = "BioProtection"
        case pinProtectedMainKey = "PinProtection"
        case pinProtectionSalt = "PinProtection.salt"
        case unprotectedMainKey = "NoneProtection"
    }

    enum PrivateKeyLabel: String {
        case biometricProtection = "BioProtection.private"
    }

    static nonisolated(unsafe) var legacyService = "ch.protonmail"

    private let legacyAccessGroup = "2SB5Z68H26.ch.protonmail.protonmail"

    init() {
        super.init(service: Self.legacyService, accessGroup: legacyAccessGroup)
    }

    func data(forKey key: Key) throws -> Data? {
        try dataOrError(forKey: key.rawValue)
    }

    func privateKey(labeled label: PrivateKeyLabel) throws -> SecKey? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrLabel: label.rawValue,
            kSecAttrAccessGroup: legacyAccessGroup,
            kSecReturnRef: true,
        ]

        var raw: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &raw)

        switch status {
        case errSecSuccess:
            return raw as! SecKey?
        case errSecItemNotFound:
            return nil
        default:
            throw Keychain.AccessError.readFailed(key: label.rawValue, error: status)
        }
    }
}
