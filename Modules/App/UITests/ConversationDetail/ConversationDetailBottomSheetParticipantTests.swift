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

final class ConversationDetailBottomSheetParticipantTests: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 440534
    func testSenderBottomSheetWhenNotAContact() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_440534.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440534.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440534.json",
                wildcardMatch: true
            )
        )

        let sender = UITestActionSheetParticipantEntry(
            avatarText: "TF",
            participantName: "Test Free Account",
            participantAddress: "notsofree@proton.black"
        )

        verifyParticipantBottomSheet(
            participant: sender,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultSenderActions
        ) {
            $0.tapSender()
        }
    }

    /// TestId 440534/2
    func testSenderBottomSheetWhenNotAContactAndEmptyDisplayName() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_440534_2.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440534_2.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440534_2.json",
                wildcardMatch: true
            )
        )

        let sender = UITestActionSheetParticipantEntry(
            avatarText: "N",
            participantName: "notsofree@proton.black",
            participantAddress: "notsofree@proton.black"
        )

        verifyParticipantBottomSheet(
            participant: sender,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultSenderActions
        ) {
            $0.tapSender()
        }
    }

    /// TestId 440536
    func testParticipantBottomSheetInToFieldWhenNotAContact() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_440534.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440534.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440534.json",
                wildcardMatch: true
            )
        )

        let recipient = UITestActionSheetParticipantEntry(
            avatarText: "YB",
            participantName: "Young Bee",
            participantAddress: "youngbee@proton.black"
        )

        verifyParticipantBottomSheet(
            participant: recipient,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultRecipientActions
        ) {
            $0.tapRecipient(ofType: .to, atIndex: 0)
        }
    }

    /// TestId 440537
    /// Final behaviour TBC, keeping it as is for now.
    func testSenderBottomSheetFromSentFolder() async {
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
                localPath: "messages_440537.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440537.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440537.json",
                wildcardMatch: true
            )
        )

        let sender = UITestActionSheetParticipantEntry(
            avatarText: "YB",
            participantName: "Young Bee",
            participantAddress: "youngbee@proton.black"
        )

        verifyParticipantBottomSheet(
            destination: .sent,
            participant: sender,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultSenderActions
        ) {
            $0.tapSender()
        }
    }

    /// TestId 440541
    func testParticipantBottomSheetInCcFieldWhenNotAContact() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_440541.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440541.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440541.json",
                wildcardMatch: true
            )
        )

        let recipient = UITestActionSheetParticipantEntry(
            avatarText: "Y",
            participantName: "youngbee@proton.black",
            participantAddress: "youngbee@proton.black"
        )

        verifyParticipantBottomSheet(
            destination: .inbox,
            participant: recipient,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultRecipientActions
        ) {
            $0.tapRecipient(ofType: .cc, atIndex: 0)
        }
    }

    /// TestId 440542
    func testParticipantBottomSheetInBccFieldWhenNotAContact() async {
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
                localPath: "messages_440542.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_440542.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_440542.json",
                wildcardMatch: true
            )
        )

        let recipient = UITestActionSheetParticipantEntry(
            avatarText: "N",
            participantName: "notsofree@proton.black",
            participantAddress: "notsofree@proton.black"
        )

        verifyParticipantBottomSheet(
            destination: .sent,
            participant: recipient,
            entries: UITestBottomSheetDefaultEntries.MessageActions.defaultRecipientActions
        ) {
            $0.tapRecipient(ofType: .bcc, atIndex: 0)
        }
    }

    private func verifyParticipantBottomSheet(
        destination: UITestDestination = .inbox,
        participant: UITestActionSheetParticipantEntry,
        entries: [UITestBottomSheetDynamicEntry],
        interaction: (ConversationDetailRobot) -> Void
    ) {
        navigator.navigateTo(destination)

        MailboxRobot {
            $0.tapEntryAt(index: 0)
        }

        ConversationDetailRobot {
            $0.waitForLoaderToDisappear()
            $0.toggleCollapsedHeader(at: 0)
            interaction($0)
        }

        ActionBottomSheetRobot {
            $0.verifyShown()
            $0.hasParticipant(entry: participant)
            $0.hasEntries(entries)
        }
    }
}
