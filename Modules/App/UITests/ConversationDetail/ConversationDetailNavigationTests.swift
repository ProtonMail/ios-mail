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

final class ConversationDetailNavigationTests: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 433919, 433929
    func testMailboxToConversationDetailsNavigation() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_433919.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_433919.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_433919.json",
                wildcardMatch: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.tapBackButton()
        }

        MailboxRobot {
            $0.verifyMailboxTitle(folder: UITestFolder.system(.inbox))
        }
    }

    /// TestId 435484
    func testSentFoldersToConversationDetailsNavigation() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_435484.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435484.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/DWnWL7bA5ZE2vuvUzAxz_AoJQURQS7OgXGMecb13JOi3UlzzrZ-5Chw9z5LbP_69o-zWUA92L5Jwb4zVImAeNQ==",
                localPath: "message-id_435484.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435484_2.json"
            )
        )

        navigator.navigateTo(.sent)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 1)
            $0.hasExpandedEntries(indexes: 2, 3)
        }
    }

    /// TestId 435484/2
    func testSentFoldersToConversationDetailsNavigationWhenMessageIsLatest() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_435484.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435484_2.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/DWnWL7bA5ZE2vuvUzAxz_AoJQURQS7OgXGMecb13JOi3UlzzrZ-5Chw9z5LbP_69o-zWUA92L5Jwb4zVImAeNQ==",
                localPath: "message-id_435484.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435484_2.json"
            )
        )

        navigator.navigateTo(.sent)

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

    /// TestId 435485
    func testMessageModeToConversationDetailsNavigationFromInboxWhenMessageIsLatest() async {
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
                localPath: "messages_435485.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435485.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435484_2.json"
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 1, 2)
            $0.hasExpandedEntries(indexes: 3)
        }
    }

    /// TestId 435485/2
    func testMessageModeToConversationDetailsNavigationFromInbox() async {
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
                localPath: "messages_435485.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435485.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/DUtKnnR2QSGRfPTqza8fUOdm-DTYfgAfjvQz3WCIeCKMFzutcRBTCtxIPe0p0xTbbXuP4wfGGl66lwwRg91RHQ==",
                localPath: "message-id_435485.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435484_2.json"
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 1)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 2)
            $0.hasExpandedEntries(indexes: 1, 3)
        }
    }

    /// Testid 435505
    func testMessageModeToConversationDetailsNavigationFromInboxWithUnreadMessages() async {
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
                localPath: "messages_435505.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_435505.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/XCEqUvpthaRB8FOI7vorSyKtHF93V8krSGSXy9KAJrSbxViEqDHIWYQDRhHzbJnaTu0kMryHLOEB4ReM7rZU1A==",
                localPath: "message-id_435505.json"
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyShown()
            $0.waitForLoaderToDisappear()

            $0.hasCollapsedEntries(indexes: 0, 1, 2)
            $0.hasExpandedEntries(indexes: 3)
        }
    }
}
