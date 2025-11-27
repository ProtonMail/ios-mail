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

final class MailboxSidebarTests: PMUIMockedNetworkTestCase {
    /// TestId 425682
    func testSidebarMenuOpening() async {
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
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.verifyShown()
        }
    }

    /// TestId 425968
    func testSidebarNavigation() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_425968.json",
                ignoreQueryParams: true
            )
        )

        let expectedInboxEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: UITestAvatarItemEntry.initials("M"),
            sender: "mobileappsuitesting2",
            subject: "Test message",
            date: "Mar 6, 2023",
            count: nil
        )

        let expectedArchiveEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: UITestAvatarItemEntry.initials("M"),
            sender: "mobileappsuitesting3",
            subject: "Base subject",
            date: "Mar 28, 2023",
            count: nil
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.inbox))
            $0.hasEntries(entries: expectedInboxEntry)
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.openArchive()
            $0.verifyHidden()
        }

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.archive))
            $0.hasEntries(entries: expectedArchiveEntry)
        }
    }

    /// TestId 426538, 426539, 426540
    func testSidebarCounters() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            useDefaultMessagesCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_426538.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_426538.json",
                serveOnce: true
            )
        )

        let expectedBadgeEntry = UITestSidebarListItemEntry(
            hasIcon: true,
            text: "Inbox",
            badge: "1"
        )
        let expectedNoBadgeEntry = UITestSidebarListItemEntry(
            hasIcon: true,
            text: "Draft",
            badge: nil
        )
        let expectedCappedEntry = UITestSidebarListItemEntry(
            hasIcon: true,
            text: "Sent",
            badge: "999+"
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.hasEntries(expectedBadgeEntry, expectedNoBadgeEntry, expectedCappedEntry)
        }
    }
}
