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

final class MailboxSidebarFoldersTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.TinyBarracuda
    }

    private let standaloneEntry = UITestSidebarListItemEntry(text: "Main Folder", badge: "1", expandable: false)
    private let parentEntry = UITestSidebarListItemEntry(text: "Parent Folder", badge: "2", expandable: true)
    private let childEntry = UITestSidebarListItemEntry(text: "Child Folder", expandable: true)
    private let subChildEntry = UITestSidebarListItemEntry(text: "Subchild Folder", expandable: false)

    /// TestId 448501, 448505
    func testSidebarFoldersCollapsed() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultFolders: false,
            useDefaultConversationCount: false,
            useDefaultMessagesCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448501.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_448501.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=3",
                localPath: "labels-type3_448501.json",
                serveOnce: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.hasEntries(standaloneEntry, parentEntry)
            $0.hasNoEntries(childEntry, subChildEntry)
        }
    }

    /// TestId 448507, 448513
    func testSidebarFoldersExpansion() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultFolders: false,
            useDefaultConversationCount: false,
            useDefaultMessagesCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448507.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_448507.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=3",
                localPath: "labels-type3_448507.json",
                serveOnce: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.toggleItemExpansion(withLabel: parentEntry.text)
            $0.hasEntries(parentEntry, childEntry)
            $0.hasNoEntries(subChildEntry)

            $0.toggleItemExpansion(withLabel: childEntry.text)
            $0.hasEntries(parentEntry, childEntry, subChildEntry)
        }
    }

    /// TestId 448511
    func testSidebarFoldersExpansionIsRetainedOnSidebarReopening() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultFolders: false,
            useDefaultConversationCount: false,
            useDefaultMessagesCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448511.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_448511.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=3",
                localPath: "labels-type3_448511.json",
                serveOnce: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.toggleItemExpansion(withLabel: parentEntry.text)
            $0.hasEntries(parentEntry, childEntry)
            $0.hasNoEntries(subChildEntry)

            $0.dismiss()
            $0.verifyHidden()
        }

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.hasEntries(parentEntry, childEntry)
            $0.hasNoEntries(subChildEntry)
        }
    }

    /// TestId 448516, 448517
    func testSidebarFoldersCollapsing() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultFolders: false,
            useDefaultConversationCount: false,
            useDefaultMessagesCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448516.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_448516.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=3",
                localPath: "labels-type3_448516.json",
                serveOnce: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.openSidebarMenu()
        }

        SidebarMenuRobot {
            $0.toggleItemExpansion(withLabel: parentEntry.text)
            $0.hasEntries(parentEntry, childEntry)
            $0.hasNoEntries(subChildEntry)

            $0.toggleItemExpansion(withLabel: childEntry.text)
            $0.hasEntries(parentEntry, childEntry, subChildEntry)

            $0.toggleItemExpansion(withLabel: childEntry.text)
            $0.hasEntries(parentEntry, childEntry)
            $0.hasNoEntries(subChildEntry)

            $0.toggleItemExpansion(withLabel: parentEntry.text)
            $0.hasEntries(parentEntry)
            $0.hasNoEntries(childEntry, subChildEntry)
        }
    }

    /// TestId 448506
    func testCreateFolderButton() async {
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
            $0.tapCreateFolder()
        }

        CreateFolderLabelRobot {
            $0.verifyShown()
        }
    }
}
