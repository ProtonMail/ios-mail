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

final class SaveEventResponseInCacheUseCase {
    typealias Dependencies = AnyObject & HasCoreDataContextProviderProtocol

    unowned let dependencies: Dependencies
    let userID: UserID
    private let encoder = JSONEncoder()

    init(dependencies: Dependencies, userID: UserID) {
        self.dependencies = dependencies
        self.userID = userID
    }

    func execute(response: EventAPIResponse) throws {
        try dependencies.contextProvider.write { context in
            self.processContact(response: response, context: context)
            self.processEmail(response: response, context: context)
            self.processLabel(response: response, context: context)
            self.processConversation(response: response, context: context)
        }
    }

    private func processContact(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let contactResponses = response.contacts else {
            return
        }
        for contact in contactResponses {
            guard let eventAction = EventAction(rawValue: contact.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let contactObject = Contact.contactFor(contactID: contact.id, userID: self.userID, in: context) {
                    context.delete(contactObject)
                }
            case .create, .update:
                guard let contact = contact.contact else {
                    continue
                }
                let contactObject = Contact.contactFor(
                    contactID: contact.id,
                    userID: self.userID,
                    in: context
                ) ?? Contact(context: context)

                contactObject.contactID = contact.id
                contactObject.name = contact.name
                contactObject.uuid = contact.uid
                contactObject.size = NSNumber(value: contact.size)
                contactObject.createTime = Date(timeIntervalSince1970: .init(contact.createTime))
                contactObject.modifyTIme = Date(timeIntervalSince1970: .init(contact.modifyTime))
                contactObject.userID = self.userID.rawValue
                contactObject.isSoftDeleted = false
                contactObject.isDownloaded = false

                if let encodedCards = try? encoder.encode(contact.cards) {
                    contactObject.cardData = String(data: encodedCards, encoding: .utf8) ?? ""
                }

                for email in contact.contactEmails {
                    updateEmailInCache(
                        email: email,
                        contactObject: contactObject,
                        context: context
                    )
                }
            default:
                break
            }
        }
    }

    private func processEmail(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let contactEmailResponses = response.contactEmails else {
            return
        }
        for email in contactEmailResponses {
            guard let eventAction = EventAction(rawValue: email.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let emailObject = Email.emailFor(emailID: email.id, userID: userID, in: context) {
                    context.delete(emailObject)
                }
            case .create, .update:
                guard let email = email.contactEmail else {
                    continue
                }
                updateEmailInCache(email: email, contactObject: nil, context: context)
            default:
                break
            }
        }
    }

    private func processLabel(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let labelResponses = response.labels else {
            return
        }
        for labelResponse in labelResponses {
            guard let eventAction = EventAction(rawValue: labelResponse.action) else {
                continue
            }
            switch eventAction {
            case .delete:
                if let labelObject = Label.labelFor(labelID: labelResponse.id, userID: userID, in: context) {
                    context.delete(labelObject)
                }
            case .create, .update:
                guard let label = labelResponse.label else {
                    continue
                }
                let labelObject = Label.labelFor(labelID: label.id, userID: userID, in: context) ?? Label(context: context)
                labelObject.labelID = label.id
                labelObject.userID = userID.rawValue
                labelObject.name = label.name
                labelObject.path = label.path
                labelObject.type = NSNumber(value: label.type)
                labelObject.color = label.color
                labelObject.order = NSNumber(value: label.order)
                labelObject.notify = NSNumber(value: label.notify)
                labelObject.sticky = NSNumber(value: label.sticky)
                labelObject.parentID = label.parentId ?? .empty
            default:
                break
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func processConversation(response: EventAPIResponse, context: NSManagedObjectContext) {
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
                conversationObject.expirationTime =
                    Date(timeIntervalSince1970: TimeInterval(conversation.expirationTime))
                conversationObject.size = NSNumber(value: conversation.size)

                let labels = conversationObject.mutableSetValue(forKey: "labels")
                labels.removeAllObjects()
                for label in conversation.labels {
                    let labelObject = ContextLabel(context: context)
                    labelObject.labelID = label.id
                    labelObject.userID = userID.rawValue
                    labelObject.conversationID = conversationObject.conversationID
                    labelObject.messageCount = NSNumber(value: label.contextNumMessages)
                    labelObject.unreadCount = NSNumber(value: label.contextNumUnread)
                    labelObject.time = Date(timeIntervalSince1970: TimeInterval(label.contextTime))
                    labelObject.expirationTime = Date(timeIntervalSince1970: TimeInterval(label.contextExpirationTime))
                    labelObject.size = NSNumber(value: label.contextSize)
                    labelObject.attachmentCount = NSNumber(value: label.contextNumAttachments)
                    labelObject.order = conversationObject.order

                    labelObject.conversation = conversationObject
                }
            default:
                break
            }
        }
    }

    private func updateEmailInCache(
        email: ContactEmail,
        contactObject: Contact?,
        context: NSManagedObjectContext
    ) {
        let emailObject = Email.emailFor(
            emailID: email.id,
            userID: self.userID,
            in: context
        ) ?? Email(context: context)

        if let encodedType = try? encoder.encode(email.type) {
            emailObject.type = String(data: encodedType, encoding: .utf8) ?? ""
        }

        emailObject.emailID = email.id
        emailObject.email = email.email
        emailObject.name = email.name
        emailObject.defaults = NSNumber(value: email.defaults)
        emailObject.order = NSNumber(value: email.order)
        emailObject.lastUsedTime = Date(timeIntervalSince1970: .init(email.lastUsedTime))
        emailObject.contactID = email.contactID
        if let contactObject = contactObject {
            emailObject.contact = contactObject
        }
        emailObject.userID = self.userID.rawValue

        let labels = emailObject.mutableSetValue(forKey: "labels")
        labels.removeAllObjects()
        for label in email.labelIDs {
            if let label = Label.labelFor(labelID: label, userID: self.userID, in: context) {
                labels.add(label)
            }
        }
    }
}
