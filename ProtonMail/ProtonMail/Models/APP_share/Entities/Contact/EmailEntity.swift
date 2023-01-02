// Copyright (c) 2022 Proton AG
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

struct EmailEntity: Equatable, Hashable {
    private(set) var objectID: ObjectID
    private(set) var contactID: ContactID
    private(set) var isContactDownloaded: Bool
    private(set) var userID: UserID
    private(set) var emailID: EmailID
    private(set) var email: String
    private(set) var name: String
    /// `false` if the contact contains custom sending preferences, `true` otherwise
    private(set) var defaults: Bool
    /// The contact contains extra security sending preferences that affect how
    /// a message must be sent.
    /// e.g. use specific public key to encrypt the message, sign the message,
    /// use specific PGP scheme....
    var hasSendingPreferences: Bool {
        defaults == false
    }

    private(set) var order: Int
    private(set) var type: String
    private(set) var lastUsedTime: Date?

    private(set) var contactCreateTime: Date?
    let contactName: String
}

extension EmailEntity {
    init(email: Email) {
        self.objectID = .init(rawValue: email.objectID)
        self.contactID = ContactID(email.contactID)
        self.isContactDownloaded = email.contact.isDownloaded
        self.userID = UserID(email.userID)
        self.emailID = EmailID(email.emailID)
        self.email = email.email
        self.name = email.name
        self.defaults = email.defaults.boolValue
        self.order = email.order.intValue
        self.type = email.type
        self.lastUsedTime = email.lastUsedTime
        self.contactCreateTime = email.contact.createTime
        self.contactName = email.contact.name
    }

    static func convert(from coreDataSet: NSSet) -> [EmailEntity] {
        coreDataSet.allObjects
            .compactMap { item in
                guard let email = item as? Email else { return nil }
                return EmailEntity(email: email)
            }
            .sorted(by: { $0.order < $1.order })
    }
}
