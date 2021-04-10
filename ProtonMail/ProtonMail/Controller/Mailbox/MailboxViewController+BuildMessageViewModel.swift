//
//  MailboxViewController+BuildMessageViewModel.swift
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
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import PMUIFoundations

extension MailboxViewController {

    func buildNewMailboxMessageViewModel(message: Message) -> NewMailboxMessageViewModel {
        let labelId = viewModel.labelID
        let isSelected = self.viewModel.selectionContains(id: message.messageID)

        let senderName = message.senderName(labelId: labelId, replacingEmails: replacingEmails)

        let initial = senderName.isEmpty ? "?" : senderName.shortName()
        let sender = senderName.isEmpty ?
            "(\(String(format: LocalString._mailbox_no_recipient)))" : senderName

        return NewMailboxMessageViewModel(
            location: Message.Location(rawValue: viewModel.labelID),
            isLabelLocation: message.isLabelLocation(labelId: labelId),
            messageLocation: message.messageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            style: listEditing ? .selection(isSelected: isSelected) : .normal,
            initial: initial.apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: sender,
            time: message.messageTime,
            isForwarded: message.forwarded,
            isReply: message.replied,
            isReplyAll: message.repliedAll,
            topic: message.subject,
            isStarred: message.starred,
            hasAttachment: message.numAttachments.intValue > 0,
            tags: createTags(message: message)
        )
    }

    private func createTags(message: Message) -> [TagViewModel] {
        let expirationTag = createTagFromExpirationDate(message: message)
        let labelsTags = createTagFromLabels(message: message)
        return [expirationTag].compactMap { $0 } + labelsTags
    }

    private func createTagFromExpirationDate(message: Message) -> TagViewModel? {
        guard let expirationTime = message.expirationTime else { return nil }

        return TagViewModel(
            title: expirationTime.countExpirationTime.apply(style: FontManager.OverlineRegularInteractionStrong),
            icon: Asset.mailHourglass.image,
            color: UIColorManager.InteractionWeak
        )
    }

    private func createTagFromLabels(message: Message) -> [TagViewModel] {
        message.orderedLabels.map { label in
            TagViewModel(
                title: label.name.apply(style: FontManager.OverlineSemiBoldTextInverted),
                icon: nil,
                color: UIColor(hexString: label.color, alpha: 1.0)
            )
        }
    }

}

private extension Message {

    var orderedLabels: [Label] {
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = labels.filtered(using: predicate)
        return allLabels
            .compactMap { $0 as? Label }
            .filter { $0.type == 1 }
            .sorted(by: { $0.order.intValue < $1.order.intValue })
    }

    var isCustomFolder: Bool {
        let predicate = NSPredicate(format: "labelID MATCHES %@", "(?!^\\d+$)^.+$")
        let allLabels = labels.filtered(using: predicate)
        return allLabels.compactMap { $0 as? Label }.filter { $0.type == 3 }.count > 0
    }

    var messageLocation: Message.Location? {
        labels
            .compactMap { $0 as? Label }
            .map(\.labelID)
            .compactMap(Message.Location.init)
            .filter { $0 != .allmail && $0 != .starred }
            .first
    }

    func isLabelLocation(labelId: String) -> Bool {
        labels
            .compactMap { $0 as? Label }
            .filter { !$0.exclusive }
            .map(\.labelID)
            .filter { Message.Location(rawValue: $0) == nil }
            .contains(labelId)
    }

    func senderName(labelId: String, replacingEmails: [Email]) -> String {
        if labelId == Message.Location.sent.rawValue || draft {
            return allEmailAddresses(replacingEmails)
        } else {
            return displaySender(replacingEmails)
        }
    }

    var messageTime: String {
        guard let time = time, let displayString = NSDate.stringForDisplay(from: time) else { return .empty }
        return displayString
    }

}

private extension Date {

    var countExpirationTime: String {
        let distance: TimeInterval
        if #available(iOS 13.0, *) {
            distance = Date().distance(to: self)
        } else {
            distance = timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
        }

        if distance > 86400 {
            let day = Int(distance / 86400)
            return "\(day) " + (day > 1 ? LocalString._days : LocalString._day)
        } else if distance > 3600 {
            let hour = Int(distance / 3600)
            return "\(hour) " + (hour > 1 ? LocalString._hours : LocalString._hour)
        } else {
            let minute = Int(distance / 60)
            return "\(minute) " + (minute > 1 ? LocalString._minutes : LocalString._minute)
        }
    }

}
