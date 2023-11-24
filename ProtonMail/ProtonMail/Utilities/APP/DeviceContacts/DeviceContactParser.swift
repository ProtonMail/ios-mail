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

    static func parseDeviceContact(
        _ deviceContact: DeviceContact,
        userKey: Key,
        userPassphrase: Passphrase
    ) throws -> DeviceContactParsedData {
        guard let vCardType2 = PMNIVCard.createInstance(),
              let vCardType3 = PMNIEzvcard.parseFirst(deviceContact.vCard)
        else {
            throw DeviceContactParserError.errorInstantiatingVCard
        }

        // name
        let fullName = deviceContact.fullName ?? LocalString._general_unknown_title
        let name = PMNIFormattedName.createInstance(fullName)
        vCardType2.setFormattedName(name)
        vCardType3.clearFormattedName()

        // emails
        let (vCardObjects, plainTextEmails) = extractEmails(from: vCardType3)
        vCardType2.setEmails(vCardObjects)
        vCardType3.clearEmails()

        // cards
        let uuid = PMNIUid.createInstance(deviceContact.identifier.uuid)
        let cardType2 = AppleContactParser
            .createCard2(by: vCardType2, uuid: uuid, userKey: userKey, passphrase: userPassphrase)
        let cardType3 = AppleContactParser
            .createCard3(by: vCardType3, userKey: userKey, passphrase: userPassphrase, uuid: uuid)

        guard let cardType2, let cardType3 else {
            throw DeviceContactParserError.errorParsingVCard
        }

        return DeviceContactParsedData(name: fullName, emails: plainTextEmails, cards: [cardType2, cardType3])
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
