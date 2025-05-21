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
import InboxCore
import InboxSnapshotTesting
import Testing
import SwiftUI

@MainActor
struct AppProtectionSelectionScreenSnapshotTests {

    @Test
    func appProtectionSelectionScreenLayoutsCorrectly() {
        let sut = AppProtectionSelectionScreen(
            state: .init(
                currentProtection: .pin,
                availableAppProtectionMethods: [
                    .init(type: .none, isSelected: false),
                    .init(type: .pin, isSelected: true),
                    .init(type: .faceID, isSelected: false),
                ],
                autoLock: .always
            ),
            appSettingsRepository: AppSettingsRepositorySpy(),
            appProtectionConfigurator: AppProtectionConfiguratorSpy()
        )
        .environmentObject(Router<SettingsRoute>())

        assertSnapshotsOnIPhoneX(of: sut)
    }

}
