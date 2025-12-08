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

import Foundation
import XCTest

final class MailboxSelectionModeActionBarTests: PMUIMockedNetworkTestCase {
    /// TestId 426597
    func testSelectionModeShowsActionBar() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.verifyActionBarNotShown()

            $0.selectItemAt(index: 0)
            $0.verifyActionBarElements()
        }
    }

    /// TestId 426598
    func testExitSelectionModeDismissesActionBar() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemAt(index: 0)
            $0.verifyActionBarElements()

            $0.unselectItemAt(index: 0)
            $0.verifyActionBarNotShown()
        }
    }
}
