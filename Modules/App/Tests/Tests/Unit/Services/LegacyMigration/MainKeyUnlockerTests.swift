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
    func unlocksBiometricsProtectedMainKey() throws {
        try legacyKeychain.set(biometricsProtectedMainKey, forKey: .biometricsProtectedMainKey)
        try legacyKeychain.set(privateKey: secureEnclavePrivateKey, forLabel: .biometricProtection)
        try #expect(sut.biometricsProtectedMainKey() == decryptedMainKey)
    }
}

private extension MainKeyUnlockerTests {
    var decryptedMainKey: Data {
        .init(base64Encoded: "FKV6Kl0XLMG5QXYiB+3JCJANjZVvFbvqSuP7kqxKsnU=").unsafelyUnwrapped
    }

    var biometricsProtectedMainKey: Data {
        .init(base64Encoded: "BMXkPgRzsc3e8xTY+Pnndl2HjqyZJ6rN5BF2T8t973NyeSoVs1A3CQGpwiprUAQHopyKa+ovFPzPgk5gFmZsbVIWK2qxX242iy0FOBtGWaEDjv06kQkFP34IFoCpFpfx9YhBb29+KLJd2JHebSpctqY=").unsafelyUnwrapped
    }

    var secureEnclavePrivateKey: Data {
        .init(base64Encoded: "BFuwuWIvO0xD/sPsehiUj41ghuI0dsklXOcKRqjRJwHVu421b4oVRQuumEzVLOM0texCRUEeauifVmdN9NxKi7QpRBQed2nHjESWqfIehGfZDMxyr9GWw/ijGtZWOyqvoQ==").unsafelyUnwrapped
    }
}
