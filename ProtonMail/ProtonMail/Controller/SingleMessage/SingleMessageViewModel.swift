//
//  SingleMessageViewModel.swift
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

class SingleMessageViewModel {

    let message: Message
    let messageBodyViewModel: NewMessageBodyViewModel

    private(set) var starred: Bool
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    private let labelId: String

    init(labelId: String, message: Message, messageService: MessageDataService) {
        self.labelId = labelId
        self.message = message
        self.starred = message.starred
        self.messageService = messageService
        self.messageBodyViewModel = NewMessageBodyViewModel()
    }

    var messageTitle: NSAttributedString {
        NSAttributedString(string: message.title, attributes: .titleAttributes)
    }

    func starTapped() {
        starred.toggle()
        messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: starred)
    }

    func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: labelId, unRead: false)
    }

}

private extension MessageDataService {

    func fetchMessage(messageId: String) -> Message? {
        fetchMessages(withIDs: .init(array: [messageId]), in: CoreDataService.shared.mainContext).first
    }

}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {

    static var titleAttributes: [Key: Value] {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center

        return [
            .kern: 0.35,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
    }

}
