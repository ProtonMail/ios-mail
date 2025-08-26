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

final class ConversationDetailMessageItemsTests: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 434031
    func testConversationDetailCollapsedItemsDefaultPreview() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434031.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434031.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434031.json",
                wildcardMatch: true
            )
        )

        let expectedCollapsedEntries = [
            UITestConversationCollapsedItemEntry(index: 0, senderName: "notsofree@proton.black", date: "Jun 17", preview: "to youngbee@proton.black"),
            UITestConversationCollapsedItemEntry(index: 1, senderName: "notsofree@proton.black", date: "Jun 18", preview: "to youngbee@proton.black"),
            UITestConversationCollapsedItemEntry(index: 2, senderName: "Young Bee", date: "Jun 18", preview: "to notsofree@proton.black"),
        ]

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyCollapsedEntries(expectedCollapsedEntries)
        }
    }

    /// TestId 434032, 434036
    func testConversationDetailExpandCollapsedItem() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434032.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434032.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/bbalvQNqllxyrQtbOedPWNd7nJ59vO8avfaqlYQuLrRPhVaAXLWWejxTSumWT5t_F6_Qi_n61flJd6Vu5YdwFQ==",
                localPath: "message-id_434032.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/5WmuImYQ_IM1BKOZofpss-UvvPL3HdJcC6BL3lcjZ6aF14StXmC2S25nPhmaPGeMSksEuwayTYzbXBpBQ6NUTg==",
                localPath: "message-id_434032_2.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/jGpxRiTWRI2x5ti_FrhKITadh_u68wsJ8HOMRtoFx0ukr_3QNbgeC1FUv7ItWZ1RsC4xk5kizv4r1IVWGsFf6Q==",
                localPath: "message-id_434032_3.json",
                serveOnce: true
            )
        )

        let expectedExpandedEntries = [
            UITestConversationExpandedItemEntry(index: 0, senderName: "Young Bee", senderAddress: "youngbee@proton.black", date: "Jun 13", recipientsSummary: "to notsofree@proton.black"),
            UITestConversationExpandedItemEntry(index: 2, senderName: "Young Bee", senderAddress: "youngbee@proton.black", date: "Jun 16", recipientsSummary: "to Test Free Account"),
        ]

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.tapCollapsedEntry(at: 0)
            $0.hasCollapsedEntries(indexes: 1)
            $0.verifyExpandedEntries(expectedExpandedEntries)

            $0.tapExpandedEntry(at: 0)
            $0.hasCollapsedEntries(indexes: 0, 1)
            $0.hasExpandedEntries(indexes: 2)
        }
    }

    /// TestId 434032/2, 434033
    func testConversationDetailExpandMultipleCollapsedItems() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434032.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434032.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/bbalvQNqllxyrQtbOedPWNd7nJ59vO8avfaqlYQuLrRPhVaAXLWWejxTSumWT5t_F6_Qi_n61flJd6Vu5YdwFQ==",
                localPath: "message-id_434032.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/5WmuImYQ_IM1BKOZofpss-UvvPL3HdJcC6BL3lcjZ6aF14StXmC2S25nPhmaPGeMSksEuwayTYzbXBpBQ6NUTg==",
                localPath: "message-id_434032_2.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/jGpxRiTWRI2x5ti_FrhKITadh_u68wsJ8HOMRtoFx0ukr_3QNbgeC1FUv7ItWZ1RsC4xk5kizv4r1IVWGsFf6Q==",
                localPath: "message-id_434032_3.json",
                serveOnce: true
            )
        )

        let expectedExpandedEntries = [
            UITestConversationExpandedItemEntry(index: 0, senderName: "Young Bee", senderAddress: "youngbee@proton.black", date: "Jun 13", recipientsSummary: "to notsofree@proton.black"),
            UITestConversationExpandedItemEntry(index: 1, senderName: "Test Free Account", senderAddress: "notsofree@proton.black", date: "Jun 15", recipientsSummary: "to Young Bee"),
            UITestConversationExpandedItemEntry(index: 2, senderName: "Young Bee", senderAddress: "youngbee@proton.black", date: "Jun 16", recipientsSummary: "to Test Free Account"),
        ]

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.tapCollapsedEntry(at: 0)
            $0.hasExpandedEntries(indexes: 0)

            $0.tapCollapsedEntry(at: 1)
            $0.verifyExpandedEntries(expectedExpandedEntries)
        }
    }

    /// TestId 434034
    func testConversationDetailCannotCollapseLastMessage() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434034.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434034.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/bbalvQNqllxyrQtbOedPWNd7nJ59vO8avfaqlYQuLrRPhVaAXLWWejxTSumWT5t_F6_Qi_n61flJd6Vu5YdwFQ==",
                localPath: "message-id_434034.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/5WmuImYQ_IM1BKOZofpss-UvvPL3HdJcC6BL3lcjZ6aF14StXmC2S25nPhmaPGeMSksEuwayTYzbXBpBQ6NUTg==",
                localPath: "message-id_434034_2.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/jGpxRiTWRI2x5ti_FrhKITadh_u68wsJ8HOMRtoFx0ukr_3QNbgeC1FUv7ItWZ1RsC4xk5kizv4r1IVWGsFf6Q==",
                localPath: "message-id_434034_3.json",
                serveOnce: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.tapExpandedEntry(at: 2)
            $0.hasExpandedEntries(indexes: 2)
        }
    }

    /// TestId 434035
    func testConversationDetailCannotCollapseASingleMessageConversation() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434035.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434035.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434035.json",
                wildcardMatch: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.tapExpandedEntry(at: 0)
            $0.hasExpandedEntries(indexes: 0)
        }
    }
}
