// Copyright (c) 2022 Proton Technologies AG
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

import Foundation

final class Draft {
    var messageID: MessageID
    var recipientList: String
    var bccList: String
    var ccList: String
    var sendAddressID: AddressID
    var title: String
    var body: String
    var expiration: TimeInterval
    var password: String
    var passwordHint: String
    var replyTos: String
    var sender: String
    var numAttachments: Int
    var originalTime: Date?
    var nextAddressID: String?
    var unRead: Bool

    var attachments: [AttachmentEntity] = []

    var senderVO: ContactVO? {
        let data = Data(sender.utf8)
        guard let recipient = try? JSONDecoder().decode(ComposeViewModel.DecodableRecipient.self,
                                                        from: data) else {
            return nil
        }
        return .init(name: recipient.name ?? .empty, email: recipient.address)
    }

    init(rawMessage: Message) {
        self.messageID = .init(rawMessage.messageID)
        self.recipientList = rawMessage.toList
        self.bccList = rawMessage.bccList
        self.ccList = rawMessage.ccList
        if let addressID = rawMessage.addressID {
            self.sendAddressID = .init(addressID)
        } else {
            self.sendAddressID = .init(.empty)
        }
        self.title = rawMessage.title
        self.body = rawMessage.body
        self.expiration = TimeInterval(Int32(rawMessage.expirationOffset))
        self.password = rawMessage.password
        self.passwordHint = rawMessage.passwordHint
        self.replyTos = rawMessage.replyTos ?? .empty
        self.sender = rawMessage.sender ?? .empty
        self.numAttachments = rawMessage.numAttachments.intValue
        self.attachments = AttachmentEntity.convert(from: rawMessage.attachments)
        self.originalTime = rawMessage.orginalTime
        self.nextAddressID = rawMessage.nextAddressID
        self.unRead = rawMessage.unRead
    }
}
