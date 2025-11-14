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
import InboxCoreUI
import InboxIAP
import InboxSnapshotTesting
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI
import Testing

@MainActor
struct SignaturesScreenSnapshotTests {
    @Test(arguments: [MobileSignatureStatus.enabled, .disabled, .needsPaidVersion])
    func mobileSignatureStatusIsReflected(mobileSignatureStatus: MobileSignatureStatus) {
        let sut = NavigationStack {
            SignaturesScreen(
                customSettings: CustomSettingsSpy(),
                initialState: .init(mobileSignatureStatus: mobileSignatureStatus)
            )
        }
        .environmentObject(Router<SettingsRoute>())
        .environmentObject(ToastStateStore(initialState: .initial))
        .environmentObject(UpsellCoordinator(mailUserSession: .dummy, configuration: .mail))

        assertSnapshotsOnIPhoneX(of: sut, named: "\(mobileSignatureStatus)")
    }
}
