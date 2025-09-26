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
import InboxSnapshotTesting
import proton_app_uniffi
import SwiftUI
import Testing

@MainActor
struct AppSettingsSnapshotTests {

    @Test()
    func testAppSettingsLayoutCorrectly() {
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
                isAppearanceMenuShown: false
            ),
            appSettingsRepository: AppSettingsRepositorySpy()
        )

        for userInterfaceStyle in [UIUserInterfaceStyle.light, .dark] {
            assertCustomHeightSnapshot(
                matching: UIHostingController(rootView: sut).view,
                styles: [userInterfaceStyle],
                preferredHeight: 1000
            )
        }
    }

}
