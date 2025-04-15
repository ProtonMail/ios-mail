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

final class ConversationDetailHeaderMainTests: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    let collapsedHeader = UITestConversationCollapsedHeaderEntry(
        index: 0,
        senderName: "Not Proton",
        senderAddress: "no-reply@not.proton.black",
        hasOfficialBadge: false,
        date: "May 20",
        toRecipients: "to youngbee@proton.black"
    )

    let expandedHeader = UITestConversationExpandedHeaderEntry(
        index: 0,
        senderName: "Not Proton",
        senderAddress: "no-reply@not.proton.black",
        timestamp: 1716199297,
        toRecipients: [UITestHeaderRecipientEntry(index: 0, name: "youngbee@proton.black", address: "youngbee@proton.black")]
    )

    /// TestId 434551
    func testConversationDetailCollapsedHeader() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434551.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434551.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434551.json",
                wildcardMatch: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyCollapsedHeader(collapsedHeader)
        }
    }

    /// TestId 434551/2, 434552
    func testConversationDetailExpandedHeader() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434551.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434551.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434551.json",
                wildcardMatch: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.toggleCollapsedHeader(at: 0)
            $0.verifyExpandedHeader(expandedHeader)
        }
    }

    /// TestId 434551/3, 434553
    func testConversationDetailExpandedAndCollapsedHeader() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434551.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434551.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434551.json",
                wildcardMatch: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.toggleCollapsedHeader(at: 0)
            $0.verifyExpandedHeader(expandedHeader)
            $0.toggleCollapsedHeader(at: 0)
            $0.verifyCollapsedHeader(collapsedHeader)
        }
    }
}
