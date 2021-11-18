//
//  Message+Helpers.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

extension Message {

    var spam: SpamType? {
        if flag.contains(.dmarcFailed) {
            return .dmarcFailed
        }
        let isSpam = getLabelIDs().contains(Message.Location.spam.rawValue)
        return flag.contains(.autoPhishing) && (!flag.contains(.hamManual) || isSpam) ? .autoPhishing : nil
    }

    var getUnsubscribeMethods: UnsubscribeMethods? {
        guard let unsubscribeMethods = unsubscribeMethods,
              let data = unsubscribeMethods.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(UnsubscribeMethods?.self, from: data)
    }

    func recipients(userContacts: [ContactVO]) -> [String] {
        let allMessageRecipients = toList.toContacts() + ccList.toContacts() + bccList.toContacts()

        return allEmails.map { email in
            if let emailFromContacts = userContacts.first(where: { $0.email == email }),
               !emailFromContacts.name.isEmpty {
                return emailFromContacts.name
            }
            if let messageRecipient = allMessageRecipients.first(where: { $0.email == email }),
               !messageRecipient.name.isEmpty {
                return messageRecipient.name
            }
            return email
        }
    }

    var tagViewModels: [TagViewModel] {
        orderedLabels.map { label in
            TagViewModel(
                title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                icon: nil,
                color: UIColor(hexString: label.color, alpha: 1.0)
            )
        }
    }

    func senderContact(userContacts: [ContactVO]) -> ContactVO? {
        guard let sender = sender?.toContact() else { return nil }
        return userContacts.first(where: { $0.email == sender.email }) ?? sender
    }

    var isCustomFolder: Bool {
        customFolder != nil
    }

    var customFolder: Label? {
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = labels.filtered(using: predicate)
        return allLabels.compactMap { $0 as? Label }.first(where: { $0.type == 3 })
    }

    var messageLocation: Message.Location? {
        labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .compactMap(Message.Location.init)
            .first(where: { $0 != .allmail && $0 != .starred })
    }

    var orderedLocation: Message.Location? {
        labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .compactMap(Message.Location.init)
            .min { Int($0.rawValue) ?? 0 < Int($1.rawValue) ?? 0 }
    }

    var createTags: [TagViewModel] {
        [createTagFromExpirationDate].compactMap { $0 } + tagViewModels
    }

    var createTagFromExpirationDate: TagViewModel? {
        guard let expirationTime = expirationTime,
              messageLocation != .draft else { return nil }

        return TagViewModel(
            title: expirationTime.countExpirationTime.apply(style: FontManager.OverlineRegularInteractionStrong),
            icon: Asset.mailHourglass.image,
            color: ColorProvider.InteractionWeak
        )
    }

    func getLocationImage(in labelID: String) -> UIImage? {
        labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .filter { $0 == labelID }
            .compactMap(Message.Location.init)
            .first(where: { $0 != .allmail && $0 != .starred })?.originImage()

    }

    func initial(replacingEmails: [Email]) -> String {
        let senderName = self.senderName(replacingEmails: replacingEmails)
        return senderName.isEmpty ? "?" : senderName.initials()
    }

    func sender(replacingEmails: [Email]) -> String {
        let senderName = self.senderName(replacingEmails: replacingEmails)
        return senderName.isEmpty ? "(\(String(format: LocalString._mailbox_no_recipient)))" : senderName
    }

    func isLabelLocation(labelId: String) -> Bool {
        labels
            .compactMap { $0 as? Label }
            .filter { $0.type.intValue == 1 }
            .map(\.labelID)
            .filter { Message.Location(rawValue: $0) == nil }
            .contains(labelId)
    }

    func senderName(replacingEmails: [Email]) -> String {
        if isSent || draft {
            return allEmailAddresses(replacingEmails)
        } else {
            return displaySender(replacingEmails)
        }
    }

    var orderedLabels: [Label] {
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = labels.filtered(using: predicate)
        return allLabels
            .compactMap { $0 as? Label }
            .filter { $0.type == 1 }
            .sorted(by: { $0.order.intValue < $1.order.intValue })
    }

    func displaySender(_ replacingEmails: [Email]) -> String {
        guard let sender = senderContactVO else {
            assert(false, "Sender with no name or address")
            return ""
        }

        // will this be deadly slow?
        guard let email = replacingEmails.first(where: { $0.email == sender.email }) else {
            return sender.name.isEmpty ? sender.email : sender.name
        }
        let contact = email.contact
        return contact.name.isEmpty ? email.name: contact.name
    }

    func allEmailAddresses(_ replacingEmails: [Email]) -> String {
        let lists: [String] = self.allEmails.map { address in
            if let name = replacingEmails.first(where: { $0.email == address })?.name,
               !name.isEmpty {
                return name
            } else {
                return address
            }
        }
        if lists.isEmpty {
            return ""
        }
        return lists.asCommaSeparatedList(trailingSpace: true)
    }

}
