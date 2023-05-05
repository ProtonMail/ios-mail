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

import CoreData
@testable import ProtonMail

extension Message {
    convenience init(from entity: MessageEntity, context: NSManagedObjectContext) {
        self.init(context: context)
        messageID = entity.messageID.rawValue
        addressID = entity.addressID.rawValue
        conversationID = entity.conversationID.rawValue
        userID = entity.userID.rawValue
        action = entity.action
        numAttachments = NSNumber(value: entity.numAttachments)
        size = NSNumber(value: entity.size)
        spamScore = NSNumber(value: entity.spamScore.rawValue)
        flags = NSNumber(value: entity.rawFlag)
        time = entity.time
        expirationTime = entity.expirationTime
        order = NSNumber(value: entity.order)
        unRead = entity.unRead
        title = entity.title
        sender = entity.rawSender
        toList = entity.rawTOList
        ccList = entity.rawCCList
        bccList = entity.rawBCCList
        replyTos = entity.rawReplyTos
        mimeType = entity.mimeType
        body = entity.body
        for label in entity.labels {
            add(labelID: label.labelID.rawValue)
        }
        nextAddressID = entity.nextAddressID?.rawValue
        expirationOffset = Int32(entity.expirationOffset)
        isSoftDeleted = entity.isSoftDeleted
        isDetailDownloaded = entity.isDetailDownloaded
        lastModified = entity.lastModified
        orginalMessageID = entity.originalMessageID?.rawValue
        orginalTime = entity.originalTime
        passwordEncryptedBody = entity.passwordEncryptedBody
        password = entity.password
        passwordHint = entity.passwordHint
        messageStatus = .init(integerLiteral: 1)
    }
}
