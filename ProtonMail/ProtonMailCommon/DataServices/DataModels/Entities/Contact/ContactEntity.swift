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

struct ContactEntity {
    // MARK: Properties
    private(set) var objectID: ObjectID
    private(set) var contactID: ContactID
    private(set) var name: String
    private(set) var cardData: String
    private(set) var uuid: String
    private(set) var createTime: Date

    // Local properties
    private(set) var isDownloaded: Bool
    private(set) var isCorrected: Bool
    private(set) var needsRebuild: Bool
    private(set) var isSoftDeleted: Bool

    // MARK: Data relations
    private(set) var emailRelations: [EmailEntity]

    init(contact: Contact) {
        self.objectID = .init(rawValue: contact.objectID)
        self.contactID = ContactID(contact.contactID)
        self.name = contact.name
        self.cardData = contact.cardData
        self.uuid = contact.uuid
        self.createTime = contact.createTime ?? Date.distantPast

        self.isDownloaded = contact.isDownloaded
        self.isCorrected = contact.isCorrected
        self.needsRebuild = contact.needsRebuild
        self.isSoftDeleted = contact.isSoftDeleted

        self.emailRelations = EmailEntity.convert(from: contact.emails)
    }
}

extension ContactEntity {
    var displayEmails: String {
        self.emailRelations
            .map(\.email)
            .asCommaSeparatedList(trailingSpace: false)
    }

    var sectionName: String {
        let temp = self.name.lowercased()
        if temp.isEmpty || temp.count == 1 {
            return temp
        }
        let index = temp.index(after: temp.startIndex)
        return String(temp.prefix(upTo: index))
    }

    var cardDatas: [CardData] {
        guard let vCards = self.cardData.parseJson() else {
            return []
        }
        return vCards.compactMap { data in
            guard let typeValue = data["Type"] as? Int,
                  let type = CardDataType(rawValue: typeValue) else { return nil }
            let cardData = data["Data"] as? String ?? ""
            let signature = data["Signature"] as? String ?? ""
            return CardData(t: type, d: cardData, s: signature)
        }
    }
}
