//
//  ExpandedHeaderViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class ExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    var initials: String { senderName.initials() }
    var senderEmail: String { "\((message.sender?.email ?? ""))" }

    var time: String {
        guard let date = message.time else { return .empty }
        return PMDateFormatter
            .shared
            .string(from: date, weekStart: user.userinfo.weekStartValue)
    }

    var date: String? {
        guard let date = message.time else { return nil }
        return dateFormatter.string(from: date)
    }

    var size: String? { message.size.toByteCount }

    var tags: [TagUIModel] {
        message.tagUIModels
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
        return message.isCustomFolder ? IconProvider.folder : nil
    }

    var originTitle: String? {
        if let locationName = message.messageLocation?.localizedTitle {
            return locationName
        }
        return message.customFolder?.name
    }
    private(set) var senderContact: ContactVO?

    private(set) var message: MessageEntity {
        didSet {
            reloadView?()
        }
    }

    private let labelId: LabelID
    let user: UserManager

    lazy var senderName: String = {
        guard let senderInfo = self.message.sender else {
            assert(false, "Sender with no name or address")
            return ""
        }
        guard let contactName = user.contactService.getName(of: senderInfo.email) else {
            return senderInfo.name.isEmpty ? senderInfo.email: senderInfo.name
        }
        return contactName
    }()

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
            let contact = ContactVO(name: name, email: recipient.email)
            return ExpandedHeaderRecipientRowViewModel(
                name: name,
                address: emailToDisplay,
                contact: contact
            )
        }
        return ExpandedHeaderRecipientsRowViewModel(
            title: title,
            recipients: recipients
        )
    }
}
