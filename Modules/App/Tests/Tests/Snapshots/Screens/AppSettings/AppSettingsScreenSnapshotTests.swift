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

//@MainActor
//<<<<<<< HEAD:Modules/App/Tests/Tests/Snapshots/Screens/AppSettings/AppSettingsSnapshotTests.swift
//struct AppSettingsSnapshotTests {
//    @Test
//    func testAppSettingsLayoutCorrectly() {
//=======
//struct AppSettingsScreenSnapshotTests {
//    struct TestCase {
//        let appIcon: AppIcon
//        let supportsAlternateIcons: Bool
//    }
//
//    @Test(arguments: [
//        TestCase(appIcon: .default, supportsAlternateIcons: true),
//        TestCase(appIcon: .notes, supportsAlternateIcons: true),
//        TestCase(appIcon: .default, supportsAlternateIcons: false),
//    ])
//    func testAppSettingsLayoutCorrectly(testCase: TestCase) {
//        let appIconConfigurator = AppIconConfiguratorSpy()
//        appIconConfigurator.stubbedSupportsAlternateIcons = testCase.supportsAlternateIcons
//
//>>>>>>> main:Modules/App/Tests/Tests/Snapshots/Screens/AppSettings/AppSettingsScreenSnapshotTests.swift
//        let sut = AppSettingsScreen(
//            state: .init(
//                areNotificationsEnabled: false,
//                appLanguage: "English",
//                storedAppSettings: .init(
//                    appearance: .system,
//                    protection: .pin,
//                    autoLock: .always,
//                    useCombineContacts: false,
//                    useAlternativeRouting: true
//                ),
//<<<<<<< HEAD:Modules/App/Tests/Tests/Snapshots/Screens/AppSettings/AppSettingsSnapshotTests.swift
//                isAppearanceMenuShown: false,
//                isSwipeToAdjacentConversationEnabled: false
//            ),
//            appSettingsRepository: AppSettingsRepositorySpy(),
//            customSettings: CustomSettingsSpy()
//=======
//                appIcon: testCase.appIcon,
//                isAppearanceMenuShown: false
//            ),
//            appIconConfigurator: appIconConfigurator,
//            appSettingsRepository: AppSettingsRepositorySpy()
//>>>>>>> main:Modules/App/Tests/Tests/Snapshots/Screens/AppSettings/AppSettingsScreenSnapshotTests.swift
//        )
//
//        for userInterfaceStyle in [UIUserInterfaceStyle.light, .dark] {
//            assertCustomHeightSnapshot(
//                matching: UIHostingController(rootView: sut).view,
//                styles: [userInterfaceStyle],
//                preferredHeight: 1000,
//                named: "\(testCase.appIcon.title.string)_\(testCase.supportsAlternateIcons)"
//            )
//        }
//    }
//}
