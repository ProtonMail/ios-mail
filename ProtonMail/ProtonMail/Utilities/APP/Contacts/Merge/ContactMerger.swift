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
    /// - Returns: will return the resulting object of the merge. The object type will depend on the `strategy`
    func merge(
        deviceContact: DeviceContact,
        protonContact: ContactEntity
    ) throws -> Either<DeviceContact, ContactEntity> {
        let deviceContactVCard = try vCardObject(for: deviceContact)
        let protonVCards = protonVCards(for: protonContact)

        try strategy.merge(deviceContact: deviceContactVCard, protonContact: protonVCards)

        switch strategy.mergeDestination {
        case .deviceContact:
            return .left(makeDeviceContact(from: deviceContact, updating: try deviceContactVCard.vCard()))

        case .protonContact:
            let cards = try protonVCards
                .write(userKey: encryptionKey, mailboxPassphrase: mailboxPassphrase)
                .toJSONString()
            return .right(makeContactEntity(from: protonContact, updating: cards))
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

enum ContactMergerError: Error {
    case failedCreatingVCardObject
    case encryptionKeyNotFound
}
