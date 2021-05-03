//
//  NonExpandedHeaderViewModel.swift
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

import PMUIFoundations
import PromiseKit

class NonExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    var sender: NSAttributedString {
        senderName.apply(style: .Default)
    }

    var initials: NSAttributedString {
        senderName.shortName().apply(style: FontManager.body3RegularNorm)
    }

    var originImage: UIImage? {
        if let image = message.messageLocation?.originImage {
            return image
        }
        return message.isCustomFolder ? Asset.mailCustomFolder.image : nil
    }

    var time: NSAttributedString {
        message.messageTime.apply(style: FontManager.CaptionWeak)
    }

    var recipient: NSAttributedString {
        let allRecipeints = message.recipients(userContacts: userContacts)
            .joined(separator: ", ")
        let recipients = allRecipeints.isEmpty ? LocalString._undisclosed_recipients : allRecipeints
        let toText = "\(LocalString._general_to_label): ".apply(style: .toAttributes)
        return toText + recipients.apply(style: .recipientAttibutes)
    }

    var tags: [TagViewModel] {
        message.tagViewModels
    }

    var senderContact: ContactVO?

    private(set) var message: Message {
        didSet {
            reloadView?()
        }
    }

    private let labelId: String
    private let contactService: ContactDataService
    let user: UserManager

    private var userContacts: [ContactVO] {
        contactService.allContactVOs()
    }

    private var senderName: String {
        let contactsEmails = contactService.allEmails().filter { $0.userID == message.userID }
        return message.displaySender(contactsEmails)
    }

    init(labelId: String, message: Message, user: UserManager) {
        self.labelId = labelId
        self.message = message
        self.user = user
        self.contactService = user.contactService
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {

    static var toAttributes: Self {
        attributes(color: UIColorManager.TextNorm)
    }

    static var recipientAttibutes: Self {
        attributes(color: UIColorManager.TextWeak)
    }

    private static func attributes(color: UIColor) -> Self {
        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [
            .kern: 0.35,
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
    }

}
