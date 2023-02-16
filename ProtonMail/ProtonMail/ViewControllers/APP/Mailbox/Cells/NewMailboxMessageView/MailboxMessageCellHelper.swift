// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_DataModel

final class MailboxMessageCellHelper {
    func senderRowComponents(
        for message: MessageEntity,
        basedOn emailReplacements: [String: EmailEntity],
        groupContacts: [ContactGroupVO]
    ) -> [SenderRowComponent] {
        if message.isSent || message.isDraft || message.isScheduledSend {
            return [.string(message.allEmailAddresses(emailReplacements, allGroupContacts: groupContacts))]
        } else {
            return senderRowComponents(for: .message(message), basedOn: emailReplacements)
        }
    }

    func senderRowComponents(
        for conversation: ConversationEntity,
        basedOn emailReplacements: [String: EmailEntity]
    ) -> [SenderRowComponent] {
        senderRowComponents(for: .conversation(conversation), basedOn: emailReplacements)
    }

    private func senderRowComponents(
        for mailboxItem: MailboxItem,
        basedOn emailReplacements: [String: EmailEntity]
    ) -> [SenderRowComponent] {
        let senders: [Sender]

        do {
            switch mailboxItem {
            case .message(let message):
                senders = [try message.parseSender()]
            case .conversation(let conversation):
                senders = try conversation.parseSenders()
            }
        } catch {
            assertionFailure("\(error)")
            return []
        }

        return senders.reduce(into: []) { acc, sender in
            let displayableName: String

            if let contactName = emailReplacements[sender.address]?.contactName, !contactName.isEmpty {
                displayableName = contactName
            } else if !sender.name.isEmpty {
                displayableName = sender.name
            } else if !sender.address.isEmpty {
                displayableName = sender.address
            } else {
                assertionFailure("Empty Sender: \(sender)")
                return
            }

            switch acc.last {
            case .string(let accumulatedString):
                acc[acc.endIndex - 1] = .string(accumulatedString.appending(", \(displayableName)"))
            case .officialBadge:
                acc.append(.string(", \(displayableName)"))
            case .none:
                acc.append(.string(displayableName))
            }

            if sender.isFromProton {
                acc.append(.officialBadge)
            }
        }
    }
}
