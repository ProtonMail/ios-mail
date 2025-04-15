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

final class MailboxSidebarLabelsTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.TinyBarracuda
    }

    /// TestId 448520
    func testCreateLabelButton() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.tapCreateLabel()
        }

        CreateFolderLabelRobot {
            $0.verifyShown()
        }
    }

    /// TestId 448521
    func testCustomLabelDisplayedWithCounter() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultLabels: false,
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=1",
                localPath: "labels-type1_448521.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448521.json",
                serveOnce: true
            )
        )

        let labelWithCounter = UITestSidebarListItemEntry(text: "Test Label", badge: "1")
        let labelNoCounter = UITestSidebarListItemEntry(text: "Test Label 2")

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.hasEntries(labelWithCounter, labelNoCounter)
        }
    }
}
