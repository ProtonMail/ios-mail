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

import CommonCrypto
import Foundation
import Scrypt

actor MainKeyUnlocker {
    enum MainKeyUnlockerError: Error {
        case missingKeychainData
        case privateKeyNotFound
    }

    enum ProtectionMethod: CaseIterable {
        case biometrics
        case pin

        var associatedKeychainKey: LegacyKeychain.Key {
            switch self {
            case .biometrics: .biometricsProtectedMainKey
            case .pin: .pinProtectedMainKey
            }
        }
    }

    private let legacyKeychain: LegacyKeychain

    init(legacyKeychain: LegacyKeychain = .init()) {
        self.legacyKeychain = legacyKeychain
    }

    func legacyAppProtectionMethod() throws -> ProtectionMethod? {
        try ProtectionMethod.allCases.first { try legacyKeychain.data(forKey: $0.associatedKeychainKey) != nil }
    }

    /// Calling this will trigger a Face ID / Touch ID check by the system.
    func biometricsProtectedMainKey() throws -> Data {
        guard let encryptedMainKey = try legacyKeychain.data(forKey: .biometricsProtectedMainKey) else {
            throw MainKeyUnlockerError.missingKeychainData
        }

        guard let mainKeyEncryptionKey = try legacyKeychain.privateKey(labeled: .biometricProtection) else {
            throw MainKeyUnlockerError.privateKeyNotFound
        }

        return try decrypt(ciphertext: encryptedMainKey, using: mainKeyEncryptionKey)
    }

    private func decrypt(ciphertext: Data, using key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?

        let plaintext = SecKeyCreateDecryptedData(
            key,
            .eciesEncryptionStandardX963SHA256AESGCM,
            ciphertext as CFData,
            &error
        )

        if let plaintext {
            return plaintext as Data
        } else {
            throw error.unsafelyUnwrapped.takeRetainedValue()
        }
    }

    func pinProtectedMainKey(pin: PIN) throws -> Data {
        guard
            let encryptedMainKey = try legacyKeychain.data(forKey: .pinProtectedMainKey),
            let salt = try legacyKeychain.data(forKey: .pinProtectionSalt)
        else {
            throw MainKeyUnlockerError.missingKeychainData
        }

        let numberOfRoundsUsedByLegacyApp: UInt64 = 32768

        let mainKeyEncryptionKey = try scrypt(
            password: pin.digits.reduce(into: []) { acc, digit in acc += [UInt8]("\(digit)".utf8) },
            salt: [UInt8](salt),
            length: kCCKeySizeAES256,
            N: numberOfRoundsUsedByLegacyApp
        )

        let decryptedMainKey: [UInt8] = try LockedDataExtractor.decryptAndDecode(
            data: encryptedMainKey,
            using: Data(mainKeyEncryptionKey)
        )

        return Data(decryptedMainKey)
    }
}
