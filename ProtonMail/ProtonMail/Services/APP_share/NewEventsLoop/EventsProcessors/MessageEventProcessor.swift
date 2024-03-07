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

struct MessageEventProcessor {
    let userID: UserID
    let encoder: JSONEncoder
    let queueManager: QueueManager

    func process(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let messageResponses = response.messages else {
            return
        }
        for messageResponse in messageResponses {
            guard let eventAction = EventAction(rawValue: messageResponse.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let messageObject = Message.messageFor(messageID: messageResponse.id, userID: userID, in: context) {
                    let labels = messageObject.mutableSetValue(forKey: "labels")
                    labels.removeAllObjects()
                    context.delete(messageObject)
                }
            case .create, .update, .updateFlags:
                guard let message = messageResponse.message else {
                    continue
                }

                if isDraft(message),
                   let draft = Message.messageFor(messageID: message.id, userID: userID, in: context) {
                    if !isMessageBeingSent(messageID: .init(message.id)) {
                        handleDraft(draft, message: message, context: context)
                    }
                } else {
                    handleMessage(message: message, context: context)
                }
            default:
                break
            }
        }
    }

    private func handleDraft(_ draft: Message, message: MessageResponse.Message, context: NSManagedObjectContext) {
        draft.title = message.subject
        if let encodedToList = try? encoder.encode(message.toList) {
            draft.toList = String(data: encodedToList, encoding: .utf8) ?? ""
        }
        if let encodedCCList = try? encoder.encode(message.ccList) {
            draft.ccList = String(data: encodedCCList, encoding: .utf8) ?? ""
        }
        if let encodedBCCList = try? encoder.encode(message.bccList) {
            draft.bccList = String(data: encodedBCCList, encoding: .utf8) ?? ""
        }
        draft.time = Date(timeIntervalSince1970: TimeInterval(message.time))
        draft.conversationID = message.conversationID

        // For undo send action, the label of the message will change
        let labels = draft.getLabelIDs()
        labels.forEach { draft.remove(labelID: $0) }
        message.labelIDs.forEach { draft.add(labelID: $0) }
        applyLabelAddition(message, on: draft, context: context)
        applyLabelDeletion(message, on: draft, context: context)

        if let attachmentsMetadata = message.attachmentsMetadata,
           let jsonData = try? JSONEncoder().encode(attachmentsMetadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            draft.attachmentsMetadata = jsonString
        }
        draft.numAttachments = NSNumber(value: message.numAttachments)
    }

    private func handleMessage(message: MessageResponse.Message, context: NSManagedObjectContext) {
        let messageObject = Message.messageFor(messageID: message.id, userID: userID, in: context)
        ?? Message(context: context)
        messageObject.userID = userID.rawValue
        messageObject.messageID = message.id
        messageObject.order = NSNumber(value: message.order)
        messageObject.conversationID = message.conversationID
        messageObject.title = message.subject
        // TODO: check notificationMessageID, if it is the same, ignore the unread flag.
        messageObject.unRead = message.unread != 0
        if let encodedSender = try? encoder.encode(message.sender) {
            messageObject.sender = String(data: encodedSender, encoding: .utf8) ?? ""
        }
        messageObject.flags = NSNumber(value: message.flags)
        messageObject.replied = message.isReplied != 0
        messageObject.repliedAll = message.isRepliedAll != 0
        messageObject.forwarded = message.isForwarded != 0
        if let encodedToList = try? encoder.encode(message.toList) {
            messageObject.toList = String(data: encodedToList, encoding: .utf8) ?? ""
        }
        if let encodedCCList = try? encoder.encode(message.ccList) {
            messageObject.ccList = String(data: encodedCCList, encoding: .utf8) ?? ""
        }
        if let encodedBCCList = try? encoder.encode(message.bccList) {
            messageObject.bccList = String(data: encodedBCCList, encoding: .utf8) ?? ""
        }
        messageObject.time = Date(timeIntervalSince1970: TimeInterval(message.time))
        messageObject.size = NSNumber(value: message.size)
        messageObject.numAttachments = NSNumber(value: message.numAttachments)
        if message.expirationTime != 0 {
            messageObject.expirationTime = Date(timeIntervalSince1970: TimeInterval(message.expirationTime))
        } else {
            messageObject.expirationTime = nil
        }
        messageObject.addressID = message.addressID
        if let encodedAttachmentsMetadata = try? encoder.encode(message.attachmentsMetadata) {
            messageObject.attachmentsMetadata =
            String(data: encodedAttachmentsMetadata, encoding: .utf8) ?? ""
        }
        if message.snoozeTime != 0 {
            messageObject.snoozeTime = Date(timeIntervalSince1970: TimeInterval(message.snoozeTime))
        } else {
            messageObject.snoozeTime = nil
        }

        applyLabelAddition(message, on: messageObject, context: context)
        applyLabelDeletion(message, on: messageObject, context: context)

        if Set(messageObject.getLabelIDs()) != Set(message.labelIDs) {
            messageObject.getLabelIDs().forEach { messageObject.remove(labelID: $0) }
            message.labelIDs.forEach { messageObject.add(labelID: $0) }
        }

        messageObject.messageStatus = 1
    }

    private func isDraft(_ message: MessageResponse.Message) -> Bool {
        let draftIDs = [LabelLocation.draft.rawLabelID, LabelLocation.hiddenDraft.rawLabelID]
        return message.labelIDs.contains(where: { draftIDs.contains($0) })
    }

    private func applyLabelDeletion(
        _ message: MessageResponse.Message,
        on messageObject: Message,
        context: NSManagedObjectContext
    ) {
        guard let deletedLabelIDs = message.labelIDsRemoved else {
            return
        }
        let currentLabels = messageObject.mutableSetValue(forKey: "labels")
        deletedLabelIDs.forEach { deletedLabelID in
            if let label = Label.labelForLabelID(deletedLabelID, inManagedObjectContext: context) {
                currentLabels.remove(label)
            }
        }
    }

    private func applyLabelAddition(
        _ message: MessageResponse.Message,
        on messageObject: Message,
        context: NSManagedObjectContext
    ) {
        guard let addedLabelIDs = message.labelIDsAdded else {
            return
        }
        let currentLabels = messageObject.mutableSetValue(forKey: "labels")
        addedLabelIDs.forEach { newLabelID in
            if let label = Label.labelForLabelID(newLabelID, inManagedObjectContext: context) {
                currentLabels.add(label)
            }
        }
    }

    private func isMessageBeingSent(messageID: MessageID) -> Bool {
        let tasks = queueManager.messageIDsOfTasks { action in
            switch action {
            case .send:
                return true
            default:
                return false
            }
        }
        let result = tasks.contains(where: { $0 == messageID.rawValue })
        return result
    }
}
