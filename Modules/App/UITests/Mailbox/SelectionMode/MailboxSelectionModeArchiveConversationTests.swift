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

final class MailboxSelectionModeArchiveConversationTests: PMUIMockedNetworkTestCase {
    private let firstSelectableItemIndex = 0
    private let secondSelectableItemIndex = 1

    private let firstEntry = UITestMailboxListItemEntry(
        index: 0,
        avatar: UITestAvatarItemEntry.initials("F"),
        sender: "Fancy Capybara, Another Address",
        subject: "Test",
        date: "Feb 2",
        count: 4
    )

    private let secondEntry = UITestMailboxListItemEntry(
        index: 1,
        avatar: UITestAvatarItemEntry.initials("F"),
        sender: "Fancy Capybara, Sleepy Koala",
        subject: "Test 2",
        date: "Dec 20, 2023",
        count: 4
    )

    /// TestId 433907
    func skip_testSelectionModeMoveToArchiveConversationMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_433907.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/conversations/label",
                localPath: "conversation-label_base_placeholder.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: firstEntry)
            $0.selectItemAt(index: firstSelectableItemIndex)
            $0.tapAction3()

            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.openArchive()
        }

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.archive))
            $0.hasEntries(entries: firstEntry)
        }
    }

    /// TestId 433908
    func skip_testSelectionModeMultipleMoveToArchiveConversationMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_433908.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/conversations/label",
                localPath: "conversation-label_base_placeholder.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: firstEntry, secondEntry)
            $0.selectItemsAt(indexes: [firstSelectableItemIndex, secondSelectableItemIndex])
            $0.tapAction3()

            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.openArchive()
        }

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.archive))
            $0.hasEntries(entries: firstEntry, secondEntry)
        }
    }

    /// TestId 433911
    func skip_testSelectionModeMoveToArchiveConversationModeWithBeError() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_433911.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_433911.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/conversations/label",
                localPath: "error_mock.json",
                status: 500
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: firstEntry)
            $0.selectItemAt(index: firstSelectableItemIndex)
            $0.tapAction3()
            $0.waitForEntry(atIndex: firstEntry.index)

            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.openArchive()
        }

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.archive))
            $0.hasNoEntries()
        }
    }
}
