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

final class ConversationDetailBottomSheetTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 439988, 439996, 439999
    func testMessageActionBottomSheetWhenInInbox() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_439988.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_439988.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_439988.json",
                wildcardMatch: true
            )
        )

        verifyEntries(folder: .inbox, entries: UITestBottomSheetDefaultEntries.MessageActions.defaultInboxList)
    }

    /// TestId 439989
    func testMessageActionBottomSheetWhenInTrash() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_439989.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_439989.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_439989.json",
                wildcardMatch: true
            )
        )

        verifyEntries(folder: .trash, entries: UITestBottomSheetDefaultEntries.MessageActions.defaultTrashList)
    }

    /// TestId 439990
    func testMessageActionBottomSheetWhenInSpam() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_439990.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_439990.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_439990.json",
                wildcardMatch: true
            )
        )

        verifyEntries(folder: .spam, entries: UITestBottomSheetDefaultEntries.MessageActions.defaultSpamList)
    }

    /// TestId 439995
    func testMessageActionBottomSheetWhenInArchive() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_439995.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_439995.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_439995.json",
                wildcardMatch: true
            )
        )

        verifyEntries(folder: .archive, entries: UITestBottomSheetDefaultEntries.MessageActions.defaultArchiveList)
    }

    /// TestId 439998
    func testMessageActionBottomSheetWhenStarred() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_439998.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_439998.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_439998.json",
                wildcardMatch: true
            )
        )

        let entries = [
            UITestBottomSheetDynamicEntry(section: 0, index: 1, text: "Unstar")
        ]

        verifyEntries(folder: .inbox, entries: entries)
    }

    private func verifyEntries(folder: UITestDestination, entries: [UITestBottomSheetDynamicEntry]) {
        navigator.navigateTo(folder)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.waitForLoaderToDisappear()
            $0.tapThreeDots(at: 0)
        }

        ActionBottomSheetRobot {
            $0.verifyShown()
            $0.hasEntries(entries)
        }
    }
}
