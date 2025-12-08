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

final class ConversationDetailAutoExpandMessageTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 435090
    func testConversationDetailAutoExpandMessagesAllReadNoDrafts() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_435090.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435090.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/5qyohknrUVpPwoNiVsc8CsFFBZxeAvOpHFBAU-ILgmUtzF2PoLKG8LJ1mdgyrLywEI1xZQ3cAdDMx8d4DPpRvA==",
                localPath: "message-id_435090.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/bKDikxBEbUYXLio0EJeSgFvllSHlQGvfh3rvKT9qfING3MGvZvCXcdH1IDeyJmTaEbYaWWQ-1JS1M_05mhSkLg==",
                localPath: "message-id_435090_2.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/Y4qe46eeankcnCzNYaDYUuPaUu0YxQ_Fu_rs1DshuEfYIw-Q3bp5-yt9LZgfa180vfGTQtCIb9ceQiQ5Fsz8Gw==",
                localPath: "message-id_435090_3.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 1)
            $0.hasExpandedEntries(indexes: 2)
        }
    }

    /// TestId 435091
    func testConversationDetailAutoExpandMessagesAllUnreadNoDrafts() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_435091.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435091.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/UwwpjlNH-ttoDnzIp8-4mtRzcNC3nzzv3wrMnHs37VSIypTKawf6pjjDs6s82qzoLY1odtLT_JYJqTyLIwl3-w==",
                localPath: "message-id_435091.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435091_2.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 1, 2)
            $0.hasExpandedEntries(indexes: 0, 3)
        }
    }

    /// TestId 435092
    func testConversationDetailAutoExpandMessagesAllUnreadWithDraft() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_435092.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435092.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/UwwpjlNH-ttoDnzIp8-4mtRzcNC3nzzv3wrMnHs37VSIypTKawf6pjjDs6s82qzoLY1odtLT_JYJqTyLIwl3-w==",
                localPath: "message-id_435092.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/wx94UssTrPcSnn3aAFCT56COS7FyxNVknLZ5EKmf-ap6qtaEl5zN89XDeQGNy01GmTooVWI0apUvLPBhKXwYnA==",
                localPath: "message-id_435092_2.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 1, 2, 3)
            $0.hasExpandedEntries(indexes: 0, 4)
        }
    }

    /// TestId 435093
    /// To be re-enabled when ET-856 is addressed.
    func skip_testConversationDetailAutoExpandMessagesAllReadWithDraft() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_435093.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435093.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/DUtKnnR2QSGRfPTqza8fUOdm-DTYfgAfjvQz3WCIeCKMFzutcRBTCtxIPe0p0xTbbXuP4wfGGl66lwwRg91RHQ==",
                localPath: "message-id_435093.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/UwwpjlNH-ttoDnzIp8-4mtRzcNC3nzzv3wrMnHs37VSIypTKawf6pjjDs6s82qzoLY1odtLT_JYJqTyLIwl3-w==",
                localPath: "message-id_435093_2.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/DWnWL7bA5ZE2vuvUzAxz_AoJQURQS7OgXGMecb13JOi3UlzzrZ-5Chw9z5LbP_69o-zWUA92L5Jwb4zVImAeNQ==",
                localPath: "message-id_435093_3.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435093_4.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/pVrYdtltx3AbvhiHlbNMRWIC6nlm2EunRfzT0z55H0QEdMeZP2uOSc42utyTb20p9LfQi4oFLMVQbruwaFE1og==",
                localPath: "message-id_435093_5.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/_U1g2VJTaVS9W8Cf2nEWjClUIoLYVeGBW5w01PCpYMK1HtceOCs9OGSlyB7XQFFoFMFDxBQndc1bK857x3Nr4w==",
                localPath: "message-id_435093_6.json"
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 1, 2, 3)
            $0.hasExpandedEntries(indexes: 4, 5)
        }
    }
}
