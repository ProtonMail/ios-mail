// Copyright (c) 2024 Proton Technologies AG
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
@testable import proton_app_uniffi
import InboxDesignSystem
import InboxTesting
import SwiftUI
import XCTest

class SettingsScreenSnapshotTests: BaseTestCase {

    func testSettingsScreenLayoutsCorrectOnIphoneX() {
        let sut = SettingsScreen(
            state: .initial.copy(with: .testData),
            mailUserSession: MailUserSessionStub(noPointer: .init())
        )

        assertSnapshotsOnIPhoneX(of: sut)
    }

}

private class MailUserSessionStub: MailUserSession {

    override func accountDetails() async -> MailUserSessionAccountDetailsResult {
        .ok(.testData)
    }

}

private extension AccountDetails {

    static var testData: Self {
        AccountDetails(
            name: "Mocked name",
            email: "mocked.email@pm.me",
            avatarInformation: .init(text: "T", color: DS.Color.Brand.norm.toHex()!)
        )
    }

}
