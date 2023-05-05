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

extension Conversation {
    convenience init(from entity: ConversationEntity, context: NSManagedObjectContext) {
        self.init(context: context)
        conversationID = entity.conversationID.rawValue
        expirationTime = entity.expirationTime
        numAttachments = NSNumber(value: entity.attachmentCount)
        numMessages = NSNumber(value: entity.messageCount)
        order = NSNumber(value: entity.order)
        senders = entity.senders
        recipients = entity.recipients
        size = NSNumber(value: entity.size ?? 0)
        subject = entity.subject
        userID = entity.userID.rawValue
        let labelToInsert = self.mutableSetValue(forKey: "labels")
        for label in entity.contextLabelRelations {
            let l = ContextLabel(context: context)
            l.userID = entity.userID.rawValue
            l.labelID = label.labelID.rawValue
            l.conversationID = entity.conversationID.rawValue
            l.messageCount = NSNumber(value: label.messageCount)
            l.attachmentCount = NSNumber(value: label.attachmentCount)
            l.size = NSNumber(value: label.size)
            l.order = NSNumber(value: label.order)
            l.unreadCount = NSNumber(value: label.unreadCount)
            labelToInsert.add(l)
        }
    }
}
