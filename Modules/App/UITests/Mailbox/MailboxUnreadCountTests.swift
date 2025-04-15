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

final class MailboxUnreadCountTests: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Free.ChirpyFlamingo
    }

    /// TestId 448579
    func testUnreadBadgeShownOnUnreadItemsInConversationMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448579.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448579.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasUnreadFilterShown(withUnreadCount: "1")
        }
    }

    /// TestId 448580
    func testUnreadBadgeShownOnUnreadItemsInConversationModeDisabled() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMessagesCount: false,
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_placeholder_messages.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/count",
                localPath: "messages-count_448580.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_448580.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasUnreadFilterShown(withUnreadCount: "2")
        }
    }

    /// TestId 448581
    func testUnreadBadgeCountCappedAt99() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448581.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448581.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasUnreadFilterShown(withUnreadCount: "99+")
        }
    }

    /// TestId 448582
    func testUnreadBadgeNotShownOnAllRead() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448582.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448582.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasNoUnreadFilterShown()
        }
    }

    /// TestId 448692
    /// To be re-enabled when ET-983 is addressed.
    func skip_testUnreadBadgeUpdatingOnMailboxChanges() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultConversationCount: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/count",
                localPath: "conversations-count_448692.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448692.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasNoUnreadFilterShown()

            $0.selectItemAt(index: 0)
            $0.tapAction1()
            $0.hasUnreadFilterShown(withUnreadCount: "1")

            $0.selectItemAt(index: 1)
            $0.tapAction1()
            $0.hasUnreadFilterShown(withUnreadCount: "2")

            $0.selectItemAt(index: 1)
            $0.tapAction1()
            $0.hasUnreadFilterShown(withUnreadCount: "1")

            $0.selectItemAt(index: 0)
            $0.tapAction1()
            $0.hasNoUnreadFilterShown()
        }
    }
}
