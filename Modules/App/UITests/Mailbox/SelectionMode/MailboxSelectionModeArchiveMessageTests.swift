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

final class MailboxSelectionModeArchiveMessageTests: PMUIMockedNetworkTestCase {
    private let firstSelectableItemIndex = 0
    private let secondSelectableItemIndex = 1

    private let firstEntry = UITestMailboxListItemEntry(
        index: 0,
        avatar: UITestAvatarItemEntry.initials("S"),
        sender: "Sleepy Koala",
        subject: "Test",
        date: "Jul 24, 2023",
        count: nil
    )

    private let secondEntry = UITestMailboxListItemEntry(
        index: 1,
        avatar: UITestAvatarItemEntry.initials("S"),
        sender: "Sleepy Koala",
        subject: "Test 2",
        date: "Jul 20, 2023",
        count: nil
    )

    /// TestId 433909
    func skip_testSelectionModeMoveToArchiveMessageMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_placeholder_messages.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_433909.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/messages/label",
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

    /// TestId 433910
    func skip_testSelectionModeMultipleMoveToArchiveMessageMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_433910.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/messages/label",
                localPath: "message-label_base_placeholder.json"
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

    /// TestId 433912
    func skip_testSelectionModeMoveToArchiveMessageModeWithBeError() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_433912.json",
                ignoreQueryParams: true,
                serveOnce: true
            ),
            NetworkRequest(
                method: .put,
                remotePath: "/mail/v4/messages/label",
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
