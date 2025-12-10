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

import InboxSnapshotTesting
import SwiftUI
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
struct AppSettingsScreenSnapshotTests {
    struct TestCase {
        let appIcon: AppIcon
        let supportsAlternateIcons: Bool
        let isSwipeToAdjacentConversationEnabled: Bool
    }

    @Test(arguments: [
        TestCase(appIcon: .default, supportsAlternateIcons: true, isSwipeToAdjacentConversationEnabled: false),
        TestCase(appIcon: .notes, supportsAlternateIcons: true, isSwipeToAdjacentConversationEnabled: false),
        TestCase(appIcon: .default, supportsAlternateIcons: false, isSwipeToAdjacentConversationEnabled: true),
    ])
    func testAppSettingsLayoutCorrectly(testCase: TestCase) {
        let appIconConfigurator = AppIconConfiguratorSpy()
        appIconConfigurator.stubbedSupportsAlternateIcons = testCase.supportsAlternateIcons

        let sut = AppSettingsScreen(
            state: .init(
                areNotificationsEnabled: false,
                appLanguage: "English",
                storedAppSettings: .init(
                    appearance: .system,
                    protection: .pin,
                    autoLock: .always,
                    useCombineContacts: false,
                    useAlternativeRouting: true
                ),
                appIcon: testCase.appIcon,
                isAppearanceMenuShown: false,
                isSwipeToAdjacentConversationEnabled: testCase.isSwipeToAdjacentConversationEnabled
            ),
            appSettingsRepository: AppSettingsRepositorySpy(),
            customSettings: CustomSettingsSpy(),
            appIconConfigurator: appIconConfigurator
        )

        for userInterfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            assertCustomHeightSnapshot(
                matching: UIHostingController(rootView: sut).view,
                styles: [userInterfaceStyle],
                preferredHeight: 1000,
                named: "\(testCase.appIcon.title.string)_\(testCase.supportsAlternateIcons)"
            )
        }
    }
}
