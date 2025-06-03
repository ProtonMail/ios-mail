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
import SwiftUI
import Testing

@MainActor
struct PINScreenSnapshotTests {

    @Test(arguments: [
        PINScreenType.verify(reason: .changePIN),
        .verify(reason: .disablePIN),
        .confirm(pin: .empty),
        .set,
    ])
    func pinScreensLayoutCorrectly(type: PINScreenType) {
        let sut = NavigationStack {
            PINScreen(
                type: type,
                pinVerifier: PINVerifierSpy(),
                appProtectionConfigurator: AppProtectionConfiguratorSpy(),
                dismiss: {}
            )
            .environmentObject(Router<PINRoute>())
        }
        assertSnapshotsOnIPhoneX(of: sut, named: type.testName)
    }

}

private extension PINScreenType {

    var testName: String {
        switch self {
        case .confirm:
            "confirm_pin"
        case .set:
            "set_pin"
        case .verify(let reason):
            switch reason {
            case .changePIN:
                "change_pin"
            case .disablePIN, .changeToBiometry:
                "disable_pin"
            }
        }
    }

}
