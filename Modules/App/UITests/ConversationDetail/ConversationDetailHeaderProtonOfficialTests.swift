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

final class ConversationDetailHeaderProtonOfficialTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 434550
    func testConversationDetailCollapsedHeaderFromProtonOfficial() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_434550.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_434550.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_434550.json",
                wildcardMatch: true
            )
        )

        let collapsedProtonHeader = UITestConversationCollapsedHeaderEntry(
            index: 0,
            senderName: "Proton",
            senderAddress: "no-reply@notify.proton.black",
            hasOfficialBadge: true,
            date: "May 20",
            toRecipients: "to youngbee@proton.black"
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.verifyCollapsedHeader(collapsedProtonHeader)
        }
    }
}
