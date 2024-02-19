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
import Foundation

struct ConversationEventProcessor {
    let userID: UserID
    let encoder: JSONEncoder

    func process(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let conversationResponses = response.conversations else {
            return
        }
        for conversationResponse in conversationResponses {
            guard let eventAction = EventAction(rawValue: conversationResponse.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let conversationObject = Conversation.conversationFor(conversationResponse.id, userID: userID, in: context) {
                    context.delete(conversationObject)
                }
            case .create, .update, .updateFlags:
                guard let conversation = conversationResponse.conversation else {
                    continue
                }
                let conversationObject = Conversation.conversationFor(conversationResponse.id, userID: userID, in: context)
                    ?? Conversation(context: context)
                conversationObject.userID = userID.rawValue
                conversationObject.conversationID = conversation.id
                conversationObject.order = NSNumber(value: conversation.order)
                conversationObject.subject = conversation.subject

                if let encodedSenders = try? encoder.encode(conversation.senders) {
                    conversationObject.senders = String(data: encodedSenders, encoding: .utf8) ?? ""
                }
                if let encodedRecipients = try? encoder.encode(conversation.recipients) {
                    conversationObject.recipients = String(data: encodedRecipients, encoding: .utf8) ?? ""
                }
                if let encodedAttachmentsMetaData = try? encoder.encode(conversation.attachmentsMetadata) {
                    conversationObject.attachmentsMetadata =
                        String(data: encodedAttachmentsMetaData, encoding: .utf8) ?? ""
                }

                conversationObject.numMessages = NSNumber(value: conversation.numMessages)
                conversationObject.numAttachments = NSNumber(value: conversation.numAttachments)
                conversationObject.expirationTime = conversation.expirationTime != 0 ?
                Date(timeIntervalSince1970: TimeInterval(conversation.expirationTime)) : nil

                conversationObject.size = NSNumber(value: conversation.size)
                conversationObject.displaySnoozedReminder = conversation.displaySnoozedReminder

                handleContextLabel(
                    conversationObject: conversationObject,
                    conversation: conversation,
                    context: context
                )
            default:
                break
            }
        }
    }

    private func handleContextLabel(
        conversationObject: Conversation,
        conversation: ConversationResponse.Conversation,
        context: NSManagedObjectContext
    ) {
        let labels = conversationObject.mutableSetValue(forKey: "labels")
        for label in conversation.labels {
            let labelObject = ContextLabel.labelFor(
                labelID: label.id,
                conversationID: conversationObject.conversationID,
                userID: userID,
                in: context
            ) ?? ContextLabel(context: context)
            labelObject.labelID = label.id
            labelObject.userID = userID.rawValue
            labelObject.conversationID = conversationObject.conversationID
            labelObject.messageCount = NSNumber(value: label.contextNumMessages)
            labelObject.unreadCount = NSNumber(value: label.contextNumUnread)
            labelObject.time = Date(timeIntervalSince1970: TimeInterval(label.contextTime))
            if let contextExpirationTime = label.contextExpirationTime {
                let expirationTime = contextExpirationTime != 0
                ? Date(timeIntervalSince1970: TimeInterval(contextExpirationTime)) : nil
                labelObject.expirationTime = expirationTime
            }
            labelObject.size = NSNumber(value: label.contextSize)
            labelObject.attachmentCount = NSNumber(value: label.contextNumAttachments)
            labelObject.order = conversationObject.order
            if let snoozeTime = label.contextSnoozeTime {
                labelObject.snoozeTime = Date(timeIntervalSince1970: TimeInterval(snoozeTime))
            } else {
                labelObject.snoozeTime = nil
            }

            labelObject.conversation = conversationObject
        }
        let labelIDs = conversation.labels.map { $0.id }
        labels.compactMap { $0 as? ContextLabel }.forEach { label in
            if !labelIDs.contains(label.labelID) {
                labels.remove(label)
            }
        }
    }
}
