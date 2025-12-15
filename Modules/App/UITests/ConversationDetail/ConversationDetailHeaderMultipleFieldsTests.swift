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

final class ConversationDetailHeaderMultipleFieldsTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 435085, 435086, 435087
    func testConversationDetailMessagesWithMultipleRecipients() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_435085.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435085.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/5qyohknrUVpPwoNiVsc8CsFFBZxeAvOpHFBAU-ILgmUtzF2PoLKG8LJ1mdgyrLywEI1xZQ3cAdDMx8d4DPpRvA==",
                localPath: "message-id_435085.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/bKDikxBEbUYXLio0EJeSgFvllSHlQGvfh3rvKT9qfING3MGvZvCXcdH1IDeyJmTaEbYaWWQ-1JS1M_05mhSkLg==",
                localPath: "message-id_435085_2.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/Y4qe46eeankcnCzNYaDYUuPaUu0YxQ_Fu_rs1DshuEfYIw-Q3bp5-yt9LZgfa180vfGTQtCIb9ceQiQ5Fsz8Gw==",
                localPath: "message-id_435085_3.json"
            )
        )

        let firstExpandedHeader = UITestConversationExpandedHeaderEntry(
            index: 0,
            senderName: "Test Free Account",
            senderAddress: "notsofree@proton.black",
            timestamp: 1_718_884_640,
            toRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "plus@proton.black", address: "plus@proton.black")
            ],
            ccRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "free@proton.black", address: "free@proton.black")
            ]
        )

        let secondExpandedHeader = UITestConversationExpandedHeaderEntry(
            index: 1,
            senderName: "Young Bee",
            senderAddress: "youngbee@proton.black",
            timestamp: 1_718_885_017,
            toRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "Test Free Account", address: "notsofree@proton.black")
            ],
            bccRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "proton133@proton.black", address: "proton133@proton.black")
            ]
        )

        let thirdExpandedHeader = UITestConversationExpandedHeaderEntry(
            index: 2,
            senderName: "Young Bee",
            senderAddress: "youngbee@proton.black",
            timestamp: 1_718_976_443,
            toRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "Test Free Account", address: "notsofree@proton.black"),
                UITestHeaderRecipientEntry(index: 1, name: "notsofree+1@proton.black", address: "notsofree+1@proton.black"),
            ],
            ccRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "free@proton.black", address: "free@proton.black")
            ],
            bccRecipients: [
                UITestHeaderRecipientEntry(index: 0, name: "plus@proton.black", address: "plus@proton.black")
            ]
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.toggleCollapsedHeader(at: 2)
            $0.verifyExpandedHeader(thirdExpandedHeader)

            $0.tapCollapsedEntry(at: 1)
            $0.toggleCollapsedHeader(at: 1)
            $0.verifyExpandedHeader(secondExpandedHeader)

            $0.toggleCollapsedHeader(at: 0)
            $0.verifyExpandedHeader(firstExpandedHeader)
        }
    }
}
