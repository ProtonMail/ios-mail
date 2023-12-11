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
    private let deviceContact: DeviceContact
    private let protonContact: ContactEntity
    private let encryptionKey: Key
    private let userKeys: [Key]
    private let mailboxPassphrase: Passphrase

    init(
        deviceContact: DeviceContact,
        protonContact: ContactEntity,
        userKeys: [Key],
        mailboxPassphrase: Passphrase
    ) throws {
        guard let firstKey = userKeys.first else { throw ContactMergerError.encryptionKeyNotFound }
        self.encryptionKey = firstKey
        self.userKeys = userKeys
        self.mailboxPassphrase = mailboxPassphrase
        self.deviceContact = deviceContact
        self.protonContact = protonContact
    }

    /// Compares `deviceContact`and `protonContact` and merges the changes into one single contact.
    /// - Parameter strategy: determines the logic applied when merging the contacts
    /// - Returns: will return the resulting object of the merge. The object type will depend on the `strategy`
    func merge(strategy: any ContactMergeStrategy) throws -> Either<DeviceContact, ContactEntity> {
        let deviceContactVCard = try vCardObject(for: deviceContact)
        let protonVCards = protonVCards(for: protonContact)

        try strategy.merge(deviceContact: deviceContactVCard, protonContact: protonVCards)

        switch strategy.mergeResult {
        case .deviceContact:
            return .left(makeDeviceContact(withVCard: try deviceContactVCard.vCard()))

        case .protonContact:
            let cards = try protonVCards
                .write(userKey: encryptionKey, mailboxPassphrase: mailboxPassphrase)
                .toJSONString()
            return .right(makeContactEntity(withCardsData: cards))
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

    private func makeDeviceContact(withVCard vCard: String) -> DeviceContact {
        DeviceContact(
            identifier: deviceContact.identifier,
            fullName: deviceContact.fullName,
            vCard: vCard
        )
    }

    private func makeContactEntity(withCardsData cards: String) -> ContactEntity {
        ContactEntity(
            objectID: protonContact.objectID,
            contactID: protonContact.contactID,
            name: protonContact.name,
            cardData: cards,
            uuid: protonContact.uuid,
            createTime: protonContact.createTime,
            isDownloaded: protonContact.isDownloaded,
            isCorrected: protonContact.isCorrected,
            needsRebuild: protonContact.needsRebuild,
            isSoftDeleted: protonContact.isSoftDeleted,
            emailRelations: protonContact.emailRelations
        )
    }
}

enum ContactMergerError: Error {
    case failedCreatingVCardObject
    case encryptionKeyNotFound
}
