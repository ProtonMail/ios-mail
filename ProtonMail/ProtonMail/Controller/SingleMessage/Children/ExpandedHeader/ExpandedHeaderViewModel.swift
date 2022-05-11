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
        var style = FontManager.DefaultSmallStrong
        style = style.addTruncatingTail(mode: .byTruncatingMiddle)
        return senderName.apply(style: style)
    }

    var senderEmail: NSAttributedString {
        var style = FontManager.body3RegularInteractionNorm
        style = style.addTruncatingTail(mode: .byTruncatingMiddle)
        return "\((message.sender?.email ?? ""))".apply(style: style)
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
        let value = message.size
        return value.toByteCount.apply(style: .CaptionWeak)
    }

    var tags: [TagViewModel] {
        message.tagViewModels
    }

    var toData: ExpandedHeaderRecipientsRowViewModel? {
        let toList = message.toList
        var list: [ContactVO] = toList.compactMap({ $0 as? ContactVO })
        toList
            .compactMap({ $0 as? ContactGroupVO })
            .forEach { group in
                group.getSelectedEmailData()
                    .compactMap { ContactVO(name: $0.name, email: $0.email) }
                    .forEach { list.append($0) }
            }

        return createRecipientRowViewModel(
            from: list,
            title: "\(LocalString._general_to_label):"
        )
    }

    var ccData: ExpandedHeaderRecipientsRowViewModel? {
        let list = message.ccList.compactMap({ $0 as? ContactVO })
        return createRecipientRowViewModel(from: list, title: "\(LocalString._general_cc_label):")
    }

    var originImage: UIImage? {
        let id = message.messageLocation?.labelID ?? labelId
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? Asset.mailCustomFolder.image : nil
    }

    var originTitle: NSAttributedString? {
        if let locationName = message.messageLocation?.localizedTitle {
            return locationName.apply(style: .CaptionWeak)
        }
        return message.customFolder?.name.apply(style: .CaptionWeak)
    }
    private(set) var senderContact: ContactVO?

    private(set) var message: MessageEntity {
        didSet {
            reloadView?()
        }
    }

    private let labelId: LabelID
    let user: UserManager

    private var senderName: String {
        guard let senderInfo = self.message.sender else {
            assert(false, "Sender with no name or address")
            return ""
        }
        guard let contactName = user.contactService.getName(of: senderInfo.email) else {
            return senderInfo.name.isEmpty ? senderInfo.email: senderInfo.name
        }
        return contactName
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

    init(labelId: LabelID, message: MessageEntity, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
    }

    func messageHasChanged(message: MessageEntity) {
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
            let emailToDisplay = email.isEmpty ? "" : "\(email)"
            let nameFromContact = recipient.getName(in: userContacts) ?? .empty
            let name = nameFromContact.isEmpty ? email : nameFromContact
            var addressStyle = FontManager.body3RegularInteractionNorm
            addressStyle = addressStyle.addTruncatingTail(mode: .byTruncatingMiddle)
            let nameStyle = FontManager.body3RegularNorm.addTruncatingTail(mode: .byTruncatingTail)
            let contact = ContactVO(name: name, email: recipient.email)
            return ExpandedHeaderRecipientRowViewModel(
                name: name.apply(style: nameStyle),
                address: emailToDisplay.apply(style: addressStyle),
                contact: contact
            )
        }
        return ExpandedHeaderRecipientsRowViewModel(
            title: title.apply(style: FontManager.body3RegularNorm.alignment(.center)),
            recipients: recipients
        )
    }
}
