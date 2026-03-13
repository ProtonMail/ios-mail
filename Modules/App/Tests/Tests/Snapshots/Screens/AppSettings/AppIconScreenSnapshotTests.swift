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

@testable import ProtonMail

@MainActor
struct AppIconScreenSnapshotTests {
    enum TestCase {
        case discreetModeEnabled
        case discreetModeDisabled
    }

    @Test(arguments: [
        TestCase.discreetModeEnabled,
        TestCase.discreetModeDisabled,
    ])
    func appIconScreenLayoutsCorrectly(testCase: TestCase) {
        let appIconConfigurator = AppIconConfiguratorSpy()
        appIconConfigurator.alternateIconName = testCase.alternateIconName

        let sut = NavigationStack {
            AppIconScreen(appIconConfigurator: appIconConfigurator)
        }

        assertSnapshotsOnIPhoneX(of: sut, named: testCase.snapshotName)
    }
}

private extension AppIconScreenSnapshotTests.TestCase {
    var snapshotName: String {
        switch self {
        case .discreetModeEnabled:
            "discreet_mode_enabled"
        case .discreetModeDisabled:
            "discreet_mode_disabled"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .discreetModeEnabled:
            AppIcon.notes.alternateIconName
        case .discreetModeDisabled:
            nil
        }
    }
}
