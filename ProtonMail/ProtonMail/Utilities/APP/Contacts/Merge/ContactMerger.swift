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

import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreUtilities
import VCard

struct ContactMerger {
    private let strategy: ContactMergeStrategy
    private let encryptionKey: Key
    private let userKeys: [Key]
    private let mailboxPassphrase: Passphrase

    init(strategy: ContactMergeStrategy, userKeys: [Key], mailboxPassphrase: Passphrase) throws {
        self.strategy = strategy
        guard let firstKey = userKeys.first else { throw ContactMergerError.encryptionKeyNotFound }
        self.encryptionKey = firstKey
        self.userKeys = userKeys
        self.mailboxPassphrase = mailboxPassphrase
    }

    /// Compares `deviceContact`and `protonContact` and merges the changes into one single contact.
    /// - Returns: will return if the contact was updated and the resulting object of the merge
    func merge(deviceContact: DeviceContact, protonContact: ContactEntity) throws -> ContactMergeResult {
        let deviceContactVCard = try vCardObject(for: deviceContact)
        let protonVCards = protonVCards(for: protonContact)

        let hasContactBeenUpdated = try strategy.merge(deviceContact: deviceContactVCard, protonContact: protonVCards)

        switch strategy.mergeDestination {
        case .deviceContact:
            let mergedDeviceContact = makeDeviceContact(from: deviceContact, updating: try deviceContactVCard.vCard())
            return ContactMergeResult(
                hasContactBeenUpdated: hasContactBeenUpdated,
                resultingContact: .left(mergedDeviceContact)
            )

        case .protonContact:
            let cards = try protonVCards
                .write(userKey: encryptionKey, mailboxPassphrase: mailboxPassphrase)
                .toJSONString()
            let mergedProtonContact = makeContactEntity(from: protonContact, updating: cards)
            return ContactMergeResult(
                hasContactBeenUpdated: hasContactBeenUpdated,
                resultingContact: .right(mergedProtonContact)
            )
        }
    }

    private func vCardObject(for deviceContact: DeviceContact) throws -> VCardObject {
        guard let object = PMNIEzvcard.parseFirst(deviceContact.vCard) else {
            throw ContactMergerError.failedCreatingVCardObject
        }
        return VCardObject(object: object)
    }

    private func protonVCards(for contactEntity: ContactEntity) -> ProtonVCards {
        let armoredKeys = userKeys.map(\.privateKey).map(ArmoredKey.init)
        return ProtonVCards(cards: contactEntity.cardDatas, userKeys: armoredKeys, mailboxPassphrase: mailboxPassphrase)
    }

    private func makeDeviceContact(from deviceContact: DeviceContact, updating vCard: String) -> DeviceContact {
        DeviceContact(
            identifier: deviceContact.identifier,
            fullName: deviceContact.fullName,
            vCard: vCard
        )
    }

    private func makeContactEntity(from contact: ContactEntity, updating cards: String) -> ContactEntity {
        ContactEntity(
            objectID: contact.objectID,
            contactID: contact.contactID,
            name: contact.name,
            cardData: cards,
            uuid: contact.uuid,
            createTime: contact.createTime,
            isDownloaded: contact.isDownloaded,
            isCorrected: contact.isCorrected,
            needsRebuild: contact.needsRebuild,
            isSoftDeleted: contact.isSoftDeleted,
            emailRelations: contact.emailRelations
        )
    }
}

struct ContactMergeResult {
    /// Indicates whether there were differences between the contacts and if `resultingContact` was updated.
    let hasContactBeenUpdated: Bool
    /// The contact that was updated if. The type will depend on the `strategy`.
    let resultingContact: Either<DeviceContact, ContactEntity>
}

enum ContactMergerError: Error {
    case failedCreatingVCardObject
    case encryptionKeyNotFound
}
