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

import ProtonCoreDataModel

final class MailboxMessageCellHelper {
    private let contactPickerModelHelper: ContactPickerModelHelper

    init(contactPickerModelHelper: ContactPickerModelHelper) {
        self.contactPickerModelHelper = contactPickerModelHelper
    }

    func senderRowComponents(
        for message: MessageEntity,
        basedOn emailReplacements: [String: EmailEntity],
        groupContacts: [ContactGroupVO],
        shouldReplaceSenderWithRecipients: Bool) -> [SenderRowComponent] {
        if shouldReplaceSenderWithRecipients && (message.isSent || message.isDraft || message.isScheduledSend) {
            return allEmailAddresses(
                message: message,
                replacingEmails: emailReplacements,
                allGroupContacts: groupContacts
            ).reduce(into: []) { acc, emailAddress in
                if acc.isEmpty {
                    acc.append(.string(emailAddress))
                } else {
                    acc.append(.string(", \(emailAddress)"))
                }
            }
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
            case .string:
                acc.append(.string(", \(displayableName)"))
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

    func allEmailAddresses(
        message: MessageEntity,
        replacingEmails: [String: EmailEntity],
        allGroupContacts: [ContactGroupVO]
    ) -> [String] {
        var recipientLists = contactPickerModelHelper.contacts(from: message.rawTOList)
        + contactPickerModelHelper.contacts(from: message.rawCCList)
        + contactPickerModelHelper.contacts(from: message.rawBCCList)

        let groups = recipientLists.compactMap { $0 as? ContactGroupVO }
        let groupList = groups.names(allGroupContacts: allGroupContacts)
        recipientLists = recipientLists.filter { ($0 as? ContactGroupVO) == nil }

        let lists: [String] = recipientLists.map { recipient in
            let address = recipient.displayEmail ?? ""
            let name = recipient.displayName ?? ""
            let email = replacingEmails[address]
            let emailName = email?.name ?? ""
            let displayName = emailName.isEmpty ? name : emailName
            return displayName.isEmpty ? address : displayName
        }
        let result = groupList + lists
        return result
    }
}

extension Array where Element: ContactGroupVO {
    func names(allGroupContacts: [ContactGroupVO]) -> [String] {
        map { recipient in
            let groupName = recipient.contactTitle
            let group = allGroupContacts.first { $0.contactTitle == groupName }
            let totalCount = group?.contactCount ?? 0
            let selectedCount = recipient.getSelectedEmailAddresses().count
            let name = "\(groupName) (\(selectedCount)/\(totalCount))"
            return name
        }
    }
}
