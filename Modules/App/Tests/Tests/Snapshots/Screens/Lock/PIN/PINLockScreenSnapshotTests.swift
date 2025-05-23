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
import InboxTesting

class PINLockScreenSnapshotTests: BaseTestCase {

    func testPINLockScreenLayoutsCorrectly() {
        assertSnapshotsOnIPhoneX(
            of: PINLockScreen(state: .init(hideLogoutButton: false, pin: []), error: .constant(nil)) { _ in },
            named: "empty_pin"
        )
        assertSnapshotsOnIPhoneX(
            of: PINLockScreen(state: .init(
                hideLogoutButton: false,
                pin: [1, 2, 3, 4, 5, 6, 7, 8, 9]
            ), error: .constant(nil)) { _ in },
            named: "non_empty_pin"
        )
        assertSnapshotsOnIPhoneX(
            of: PINLockScreen(
                state: .init(hideLogoutButton: false, pin: []),
                error: .constant(.custom("This is the error message"))
            ) { _ in },
            named: "error_message"
        )
    }

}
