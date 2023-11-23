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

struct EmailEventProcessor {
    let userID: UserID
    let encoder: JSONEncoder

    func process(response: EventAPIResponse, context: NSManagedObjectContext) {
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
