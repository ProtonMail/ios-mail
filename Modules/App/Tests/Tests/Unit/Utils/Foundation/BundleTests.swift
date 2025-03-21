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

@testable import ProtonMail
import Testing

struct BundleTests {

    @Test(arguments: [
        (version: "0.2.0", expectedEffectiveAppVersion: "7.0.0"),
        ("6.2.0", "7.0.0"),
        ("7.0.1", "7.0.1"),
        ("11.0.1", "11.0.1"),
    ])
    func effectiveAppVersion_ReturnsCorrectVersion(version: String, expectedEffectiveAppVersion: String) async throws {
        #expect(bundle(version: version).effectiveAppVersion == expectedEffectiveAppVersion)
    }

    // MARK: - Private

    private func bundle(version: String) -> Bundle {
        BundleStub(infoDictionary: ["CFBundleShortVersionString": version])
    }

}
