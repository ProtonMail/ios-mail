//
//  ExpandedHeaderViewModel.swift
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

class ExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    var initials: NSAttributedString {
        senderName.initials().apply(style: FontManager.body3RegularNorm)
    }

    var sender: NSAttributedString {
        var style = FontManager.Default
        style = style.addTruncatingTail(mode: .byTruncatingMiddle)
        return senderName.apply(style: style)
    }

    var senderEmail: NSAttributedString {
        var style = FontManager.body3RegularInteractionNorm
        style = style.addTruncatingTail(mode: .byTruncatingMiddle)
        return "<\((message.sender?.toContact()?.email ?? ""))>".apply(style: style)
    }

    var time: NSAttributedString {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: user.userinfo.weekStartValue)
            .apply(style: FontManager.CaptionWeak)
    }

    var date: NSAttributedString? {
        guard let date = message.time else { return nil }
        return dateFormatter.string(from: date).apply(style: .CaptionWeak)
    }

    var size: NSAttributedString? {
        let value = message.size.intValue
        return value.toByteCount.apply(style: .CaptionWeak)
    }

    var tags: [TagViewModel] {
        message.tagViewModels
    }

    var toData: ExpandedHeaderRecipientsRowViewModel? {
        createRecipientRowViewModel(
            from: message.toList.toContacts(),
            title: "\(LocalString._general_to_label):"
        )
    }

    var ccData: ExpandedHeaderRecipientsRowViewModel? {
        createRecipientRowViewModel(from: message.ccList.toContacts(), title: "cc")
    }

    var originImage: UIImage? {
        let id = message.messageLocation?.rawValue ?? labelId
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? Asset.mailCustomFolder.image : nil
    }

    var originTitle: NSAttributedString? {
        if let locationName = message.messageLocation?.title {
            return locationName.apply(style: .CaptionWeak)
        }
        return message.customFolder?.name.apply(style: .CaptionWeak)
    }
    private(set) var senderContact: ContactVO?

    private(set) var message: Message {
        didSet {
            reloadView?()
        }
    }

    private let labelId: String
    let user: UserManager

    private var senderName: String {
        let contactsEmails = user.contactService.allEmails().filter { $0.userID == message.userID }
        return message.displaySender(contactsEmails)
    }

    private var userContacts: [ContactVO] {
        user.contactService.allContactVOs()
    }

    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .long
        return dateFormatter
    }

    init(labelId: String, message: Message, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    func setUp(senderContact: ContactVO?) {
        self.senderContact = senderContact
    }

    private func createRecipientRowViewModel(
        from contacts: [ContactVO],
        title: String
    ) -> ExpandedHeaderRecipientsRowViewModel? {
        guard !contacts.isEmpty else { return nil }
        let recipients = contacts.map { recipient -> ExpandedHeaderRecipientRowViewModel in
            let email = recipient.email.isEmpty ? "" : "\(recipient.email ?? "")"
            let emailToDisplay = email.isEmpty ? "" : "<\(email)>"
            let name = recipient.getName(userContacts: userContacts) ?? email
            var addressStyle = FontManager.body3RegularInteractionNorm
            addressStyle = addressStyle.addTruncatingTail(mode: .byTruncatingMiddle)
            let contact = ContactVO(name: name, email: recipient.email)
            return ExpandedHeaderRecipientRowViewModel(
                name: name.apply(style: FontManager.body3RegularInteractionNorm),
                address: emailToDisplay.apply(style: addressStyle),
                contact: contact
            )
        }
        return ExpandedHeaderRecipientsRowViewModel(
            title: title.apply(style: FontManager.body3RegularWeak),
            recipients: recipients
        )
    }
}
