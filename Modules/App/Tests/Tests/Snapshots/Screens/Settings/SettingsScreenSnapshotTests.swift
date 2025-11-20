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

import InboxDesignSystem
import InboxSnapshotTesting
import InboxTesting
import SwiftUI
import XCTest

@testable import ProtonMail
@testable import proton_app_uniffi

@MainActor
class SettingsScreenSnapshotTests: BaseTestCase {

    func testSettingsScreenLayoutsCorrectOnIphoneX() {
        let store = AppAppearanceStore(mailSession: { MailSession(noPointer: .init()) })
        let mailUserSession = MailUserSessionSpy(id: "")
        mailUserSession.stubbedAccountDetails = .testData
        mailUserSession.stubbedUser = .testData

        let sut = SettingsScreen(
            state: .initial
                .copy(\.accountInfo, to: AccountDetails.testData.settings)
                .copy(\.userSettings, to: UserSettings.mock())
                .copy(\.storageInfo, to: StorageInfo.testData),
            mailUserSession: mailUserSession,
            accountAuthCoordinator: .mock(),
            upsellCoordinator: .dummy
        )

        assertSnapshotsOnIPhoneX(of: sut.environmentObject(store), precision: 0.98)
    }

}

extension AccountDetails {

    static var testData: Self {
        AccountDetails(
            name: "Mocked name",
            email: "mocked.email@pm.me",
            avatarInformation: .init(text: "T", color: DS.Color.Brand.norm.toHex()!)
        )
    }

}

extension User {

    static var testData: Self {
        User(
            createTime: 0,
            credit: 0,
            currency: "USD",
            delinquent: 0,
            displayName: "Mocked name",
            email: "mocked.email@pm.me",
            flags: .init(
                hasTemporaryPassword: false,
                noLogin: false,
                noProtonAddress: false,
                onboardChecklistStorageGranted: false,
                protected: false,
                recoveryAttempt: false,
                sso: false,
                testAccount: false
            ),
            maxSpace: 1_073_741_824,
            maxUpload: 0,
            mnemonicStatus: .disabled,
            private: true,
            name: "",
            productUsedSpace: .init(calendar: 0, contact: 0, drive: 0, mail: 0, pass: 0),
            role: .member,
            services: 0,
            subscribed: 1,
            toMigrate: false,
            usedSpace: 107_374_182,
            userType: .proton
        )
    }

}

extension StorageInfo {

    static var testData: Self {
        StorageInfo(usedSpace: 107_374_182, maxSpace: 1_073_741_824)
    }

}
