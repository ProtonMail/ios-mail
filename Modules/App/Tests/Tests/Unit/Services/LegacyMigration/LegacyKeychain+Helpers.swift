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

@testable import InboxKeychain
@testable import ProtonMail

extension LegacyKeychain {
    static func randomInstance(function: StaticString = #function) -> Self {
        Self.legacyService = "\(function)_\(UUID().uuidString)"
        return .init()
    }

    func set(_ data: Data, forKey key: Key) throws {
        try setOrError(data, forKey: key.rawValue)
    }

    func set(_ string: String, forKey key: Key) throws {
        try setOrError(string, forKey: key.rawValue)
    }

    func set(privateKey privateKeyData: Data, forLabel label: PrivateKeyLabel) throws {
        let attributes: [CFString: Any] = [
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        ]

        var error: Unmanaged<CFError>?

        let secKey = SecKeyCreateWithData(privateKeyData as CFData, attributes as CFDictionary, &error)

        if let error {
            throw error.takeRetainedValue()
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrLabel: label.rawValue,
            kSecAttrApplicationTag: service,
            kSecAttrAccessGroup: accessGroup,
            kSecValueRef: secKey!,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            throw Keychain.AccessError.writeFailed(key: label.rawValue, error: status)
        }
    }

    func removeKeys() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: service,
            kSecAttrAccessGroup: accessGroup,
        ]

        let status = SecItemDelete(query as CFDictionary)
        assert([errSecSuccess, errSecItemNotFound].contains(status))
    }
}
