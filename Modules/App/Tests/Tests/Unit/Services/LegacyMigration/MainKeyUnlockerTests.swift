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

import InboxKeychain
import Scrypt
import Testing

@testable import ProtonMail

final class MainKeyUnlockerTests {
    private let legacyKeychain = LegacyKeychain.randomInstance()
    private lazy var sut = MainKeyUnlocker(legacyKeychain: legacyKeychain)

    deinit {
        legacyKeychain.removeEverything()
        legacyKeychain.removeKeys()
    }

    @Test
    func unlocksBiometricsProtectedMainKey() async throws {
        try legacyKeychain.set(biometricsProtectedMainKey, forKey: .biometricsProtectedMainKey)
        try legacyKeychain.set(privateKey: secureEnclavePrivateKey, forLabel: .biometricProtection)
        try await #expect(sut.biometricsProtectedMainKey() == decryptedMainKey)
    }

    @Test
    func unlocksPinProtectedMainKey() async throws {
        try legacyKeychain.set(pinProtectedMainKey, forKey: .pinProtectedMainKey)
        try legacyKeychain.set(pinProtectionSalt, forKey: .pinProtectionSalt)

        try await #expect(sut.pinProtectedMainKey(pin: .init(digits: [1, 3, 3, 7])) == decryptedMainKey)
    }

    @Test
    func whenPinIsInvalid_decodingFailsToIndicateFailure() async throws {
        try legacyKeychain.set(pinProtectedMainKey, forKey: .pinProtectedMainKey)
        try legacyKeychain.set(pinProtectionSalt, forKey: .pinProtectionSalt)

        await #expect(throws: DecodingError.self) {
            try await self.sut.pinProtectedMainKey(pin: .init(digits: [1, 1, 1, 1]))
        }
    }
}

private extension MainKeyUnlockerTests {
    var decryptedMainKey: Data {
        .init(base64Encoded: "FKV6Kl0XLMG5QXYiB+3JCJANjZVvFbvqSuP7kqxKsnU=").unsafelyUnwrapped
    }

    var biometricsProtectedMainKey: Data {
        .init(base64Encoded: "BMXkPgRzsc3e8xTY+Pnndl2HjqyZJ6rN5BF2T8t973NyeSoVs1A3CQGpwiprUAQHopyKa+ovFPzPgk5gFmZsbVIWK2qxX242iy0FOBtGWaEDjv06kQkFP34IFoCpFpfx9YhBb29+KLJd2JHebSpctqY=")
            .unsafelyUnwrapped
    }

    var secureEnclavePrivateKey: Data {
        .init(base64Encoded: "BFuwuWIvO0xD/sPsehiUj41ghuI0dsklXOcKRqjRJwHVu421b4oVRQuumEzVLOM0texCRUEeauifVmdN9NxKi7QpRBQed2nHjESWqfIehGfZDMxyr9GWw/ijGtZWOyqvoQ==").unsafelyUnwrapped
    }

    var pinProtectedMainKey: Data {
        .init(
            base64Encoded:
                "dAcGOBeHqCMJvQPyOOy303bveHdY+QmCt8RpD6xX8u6+7PLF3pnUXhn91fIb2UND5P7Se8wKkKboY9a9ayFOJMm9uviXe6jCnT9C9Mh8rT3Bn04ctKPIg1YwZXCQwz80kQ/y/tW8wWACS4xRJ70v2MG5nh9jCGsi2nZ3PfFuX4545dfK0H6K0IpdwYYaZqWT6WJrGr6x+QGkJZZc6qfzLvZ7O7lmenuzc2u/fS7+fRouUROQW/2O7bo="
        ).unsafelyUnwrapped
    }

    var pinProtectionSalt: Data {
        .init(base64Encoded: "+vhAsxgbj1c=").unsafelyUnwrapped
    }
}
