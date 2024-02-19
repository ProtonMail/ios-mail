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
import VCard

struct DeviceContactParsedData {
    let name: String
    let emails: [(address: String, type: ContactFieldType)]
    let cards: [CardData]
}

struct DeviceContactParser {

    enum DeviceContactParserError: String, Error {
        case errorInstantiatingVCard
        case errorParsingVCard
    }

    /// Parses a `DeviceContact` object to prepare the information to store it locally. Information
    /// will be distributed in two vCards. One card will be signed and the other signed and encrypted,
    /// according to Proton contact specs.
    static func parseDeviceContact(
        _ deviceContact: DeviceContact,
        userKey: Key,
        userPassphrase: Passphrase
    ) throws -> DeviceContactParsedData {
        guard let vCardToSign = PMNIVCard.createInstance(),
              let vCardToEncrypt = PMNIEzvcard.parseFirst(deviceContact.vCard)
        else {
            throw DeviceContactParserError.errorInstantiatingVCard
        }

        // formatted name
        let fullName = deviceContact.fullName ?? LocalString._general_unknown_title
        let name = PMNIFormattedName.createInstance(fullName)
        vCardToSign.setFormattedName(name)
        vCardToEncrypt.clearFormattedName()

        // emails
        let (vCardObjects, plainTextEmails) = extractEmails(from: vCardToEncrypt)
        vCardToSign.setEmails(vCardObjects)
        vCardToEncrypt.clearEmails()

        // cards
        let uuid = PMNIUid.createInstance(deviceContact.identifier.uuidNormalisedForAutoImport)
        let signedCard = AppleContactParser
            .createCard2(by: vCardToSign, uuid: uuid, userKey: userKey, passphrase: userPassphrase)
        let encryptedCard = AppleContactParser
            .createCard3(by: vCardToEncrypt, userKey: userKey, passphrase: userPassphrase, uuid: uuid)

        guard let signedCard, let encryptedCard else {
            throw DeviceContactParserError.errorParsingVCard
        }

        return DeviceContactParsedData(name: fullName, emails: plainTextEmails, cards: [signedCard, encryptedCard])
    }

    static private func extractEmails(
        from vCard: PMNIVCard
    ) -> (vCardObject: [PMNIEmail], plainText: [(address: String, type: ContactFieldType)]) {
        var index = 1
        var vCardObjects = [PMNIEmail]()
        var plainTextEmails = [(address: String, type: ContactFieldType)]()
        for email in vCard.getEmails() {
            if email.getGroup().isEmpty {
                email.setGroup("EItem\(index)")
                index += 1
            }
            vCardObjects.append(email)
            let emailType = email.getTypes().compactMap(ContactFieldType.init).first(where: { $0 != .empty }) ?? .empty
            plainTextEmails.append((email.getValue(), emailType))
        }
        return (vCardObjects, plainTextEmails)
    }
}
