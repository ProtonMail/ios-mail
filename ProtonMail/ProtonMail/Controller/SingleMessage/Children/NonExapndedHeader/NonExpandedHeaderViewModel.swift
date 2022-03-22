//
//  NonExpandedHeaderViewModel.swift
//  ProtonMail
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

import PromiseKit
import ProtonCore_UIFoundations

class NonExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    var sender: NSAttributedString {
        var style = FontManager.DefaultSmallStrong
        style = style.addTruncatingTail()
        return senderName.apply(style: style)
    }

    var senderEmail: NSAttributedString {
        var style = FontManager.body3RegularInteractionNorm
        style = style.addTruncatingTail(mode: .byTruncatingMiddle)
        return "\((message.sender?.toContact()?.email ?? ""))".apply(style: style)
    }

    var initials: NSAttributedString {
        senderName.initials().apply(style: FontManager.body3RegularNorm)
    }

    var originImage: UIImage? {
        let id = message.messageLocation?.rawValue ?? labelId
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? IconProvider.folder : nil
    }

    var time: NSAttributedString {
        guard let date = message.time else { return .empty }
        return PMDateFormatter.shared.string(from: date, weekStart: user.userinfo.weekStartValue)
            .apply(style: FontManager.CaptionWeak)
    }

    var recipient: NSAttributedString {
        let name = message.allEmailAddresses(replacingEmails,
                                             groupContacts: groupContacts)
        let recipients = name.isEmpty ? LocalString._undisclosed_recipients : name
        let toText = "\(LocalString._general_to_label): ".apply(style: .toAttributes)
        return toText + recipients.apply(style: .recipientAttibutes)
    }

    var tags: [TagViewModel] {
        message.tagViewModels
    }

    var senderContact: ContactVO?

    let user: UserManager

    private(set) var message: Message {
        didSet {
            reloadView?()
        }
    }

    lazy var replacingEmails: [Email] = { [unowned self] in
        return self.user.contactService.allEmails()
            .filter { $0.userID == self.user.userInfo.userId }
    }()

    lazy var groupContacts: [ContactGroupVO] = { [unowned self] in
        self.user.contactGroupService.getAllContactGroupVOs()
    }()

    private let labelId: String
    private let contactService: ContactDataService

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
        attributes(color: ColorProvider.TextNorm)
    }

    static var recipientAttibutes: Self {
        attributes(color: ColorProvider.TextWeak)
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
