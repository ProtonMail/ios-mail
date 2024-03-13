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

struct ContactEventProcessor {
    typealias Dependencies = AnyObject
        & HasQueueManager

    unowned let dependencies: Dependencies
    let userID: UserID
    let encoder: JSONEncoder

    func precessWithoutMetadata(response: EventAPIResponse, context: NSManagedObjectContext) {
        guard let contactResponses = response.contacts else {
            return
        }
        let createdContactIDs = Set(contactResponses.filter { $0.action == EventAction.create.rawValue }.map(\.id))
        let updatedContactIDs = Set(contactResponses.filter { $0.action == EventAction.update.rawValue }.map(\.id))
        let deletedContactIDs = Set(contactResponses.filter { $0.action == EventAction.delete.rawValue }.map(\.id))

        for contactID in deletedContactIDs {
            if let contactObject = Contact.contactFor(contactID: contactID, userID: userID, in: context) {
                context.delete(contactObject)
            }
        }

        let existingContactIDs = fetchExistingContactIDs(by: createdContactIDs, context: context)

        let contactIDsToFetch = Array(
            createdContactIDs
                .subtracting(existingContactIDs)
                .union(updatedContactIDs)
                .subtracting(deletedContactIDs)
        )

        let batches = contactIDsToFetch.chunked(into: 15)
        for batch in batches {
            let task = QueueManager.Task(
                messageID: "",
                action: .fetchContactDetail(contactIDs: batch),
                userID: userID,
                dependencyIDs: [],
                isConversation: false
            )
            dependencies.queueManager.addTask(task)
            SystemLogger.log(message: "Enqueued .fetchContactDetail with \(batch.count) IDs", category: .queue)
        }
    }

    func process(response: EventAPIResponse, context: NSManagedObjectContext) {
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

    private func fetchExistingContactIDs(by ids: Set<String>, context: NSManagedObjectContext) -> Set<String> {
        let request = NSFetchRequest<Contact>(entityName: Contact.Attributes.entityName)
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == 0 AND %K in %@",
            Contact.Attributes.userID,
            userID.rawValue,
            Contact.Attributes.isSoftDeleted,
            Contact.Attributes.contactID,
            Array(ids)
        )
        do {
            let result: [Contact] = try context.fetch(request)
            return Set(result.map(\.contactID))
        } catch {
            PMAssertionFailure(error)
            return []
        }
    }
}
