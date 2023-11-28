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
import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import VCard

final class VCardReader {
    private struct CardObject {
        let card: CardData
        let object: PMNIVCard
    }

    private let cards: [CardData]
    private var cardObjects: [CardObject] = []
    private let userKeys: [ArmoredKey]
    private let mailboxPassphrase: Passphrase

    init(cards: [CardData], userKeys: [ArmoredKey], mailboxPassphrase: Passphrase) {
        self.cards = cards
        self.userKeys = userKeys
        self.mailboxPassphrase = mailboxPassphrase
    }

    /// Call this function before trying to access the vCard's fields
    func read() throws {
        cardObjects = try cards.map { card in
            let pmniCard: PMNIVCard
            switch card.type {
            case .PlainText:
                pmniCard = try parse(card: card)
            case .EncryptedOnly:
                pmniCard = try decrypt(encryptedCard: card)
            case .SignedOnly:
                pmniCard = try verifyAndParse(signedCard: card)
            case .SignAndEncrypt:
                pmniCard = try decryptVerifyAndParse(encryptedAndSignedCard: card)
            }
            return CardObject(card: card, object: pmniCard)
        }
    }
}

// MARK: contact fields

extension VCardReader {

    func name(fromCardOfType type: CardDataType = .PlainText) -> ContactField.Name {
        guard
            let card = cardObjects.first(where: { $0.card.type == type }),
            let name = card.object.getStructuredName()
        else {
            return ContactField.Name(firstName: "", lastName: "")
        }
        return ContactField.Name(firstName: name.getGiven(), lastName: name.getFamily())
    }

    func formattedName(fromCardOfType type: CardDataType = .PlainText) -> String {
        guard let card = cardObjects.first(where: { $0.card.type == type }) else { return "" }
        return card.object.getFormattedName()?.getValue() ?? ""
    }

    func emails() -> [ContactField.Email] {
        return cardObjects.map(\.object).flatMap {
            $0.getEmails()
                .map { email in
                    ContactField.Email(
                        type: email.getTypes().mapToContactFieldType(),
                        emailAddress: email.getValue()
                    )
                }
        }
    }

    func addresses() -> [ContactField.Address] {
        return cardObjects.map(\.object).flatMap {
            $0.getAddresses()
                .map { address in
                    ContactField.Address(
                        type: address.getTypes().mapToContactFieldType(),
                        street: address.getStreetAddress(),
                        streetTwo: address.getExtendedAddress(),
                        locality: address.getLocality(),
                        region: address.getRegion(),
                        postalCode: address.getPostalCode(),
                        country: address.getCountry(),
                        poBox: address.getPoBoxes().asCommaSeparatedList(trailingSpace: false)
                    )
                }
        }
    }

    func phoneNumbers() -> [ContactField.PhoneNumber] {
        return cardObjects.map(\.object).flatMap {
            $0.getTelephoneNumbers()
                .map { number in
                    ContactField.PhoneNumber(
                        type: number.getTypes().mapToContactFieldType(),
                        number: number.getText()
                    )
                }
        }
    }

    func urls() -> [ContactField.Url] {
        return cardObjects.map(\.object).flatMap {
            $0.getUrls()
                .map { url in
                    ContactField.Url(
                        type: ContactFieldType.get(raw: url.getType()),
                        url: url.getValue()
                    )
                }
        }
    }

    func otherInfo(infoType: InformationType) -> [ContactField.OtherInfo] {
        return cardObjects.map(\.object).flatMap { object -> [ContactField.OtherInfo] in

            info(from: object, ofType: infoType)
                .map { value -> ContactField.OtherInfo in
                    ContactField.OtherInfo(type: infoType, value: value)
                }
        }
    }

    private func info(from object: PMNIVCard, ofType info: InformationType) -> [String] {
        var result: [String] = []
        switch info {
        case .birthday:
            result = object.getBirthdays().map(\.formattedBirthday)
        case .anniversary:
            result = object.getBirthdays().map { $0.getDate() }
        case .nickname:
            result = object.getNicknames().map { $0.getNickname() }
        case .title:
            result = object.getTitles().map { $0.getTitle() }
        case .organization:
            result = object.getOrganizations().map { $0.getValue() }
        case .gender:
            if let gender = object.getGender()?.getGender() { result = [gender] }
        default:
            PMAssertionFailure("VCard reader: \(info) not implemented")
        }
        return result
    }
}

// MARK: methods to obtain a PMNIVCard object

extension VCardReader {

    private func parseVCard(_ card: String) throws -> PMNIVCard {
        guard let parsedObject = PMNIEzvcard.parseFirst(card) else { throw VCardReaderError.failedParsingVCardString }
        return parsedObject
    }

    private func parse(card: CardData) throws -> PMNIVCard {
        return try parseVCard(card.data)
    }

    private func decrypt(encryptedCard: CardData) throws -> PMNIVCard {
        let decryptedData = try decrypt(text: encryptedCard.data)
        return try parseVCard(decryptedData)
    }

    private func verifyAndParse(signedCard: CardData) throws -> PMNIVCard {
        try verify(text: signedCard.data, signature: ArmoredSignature(value: signedCard.signature))
        return try parseVCard(signedCard.data)
    }

    private func decryptVerifyAndParse(encryptedAndSignedCard: CardData) throws -> PMNIVCard {
        let decryptedData = try decrypt(text: encryptedAndSignedCard.data)
        try verify(text: decryptedData, signature: ArmoredSignature(value: encryptedAndSignedCard.signature))
        return try parseVCard(decryptedData)
    }
}

// MARK: methods to verify and decrypt

extension VCardReader {

    private func verify(text: String, signature: ArmoredSignature) throws {
        var isVerified: Bool = false
        for key in userKeys {
            do {
                isVerified = try Sign.verifyDetached(
                    signature: signature,
                    plainText: text,
                    verifierKey: key,
                    verifyTime: CryptoGo.CryptoGetUnixTime()
                )
                && key.value.check(passphrase: mailboxPassphrase)

                if isVerified {
                    break
                }
            } catch {}
        }
        if !isVerified {
            throw VCardReaderError.failedVerifyingCard
        }
    }

    private func decrypt(text: String) throws -> String {
        var decryptedText: String?
        var caughtError: Error?
        for key in userKeys {
            do {
                decryptedText = try text.decryptMessageWithSingleKeyNonOptional(key, passphrase: mailboxPassphrase)
            } catch {
                caughtError = error
            }
        }
        guard let decryptedText else {
            if let caughtError { throw caughtError }
            throw VCardReaderError.failedDecryptingVCard
        }
        return decryptedText
    }
}

enum VCardReaderError: Error {
    case failedParsingVCardString
    case failedDecryptingVCard
    case failedVerifyingCard
}

private extension Array where Element == String {

    func mapToContactFieldType() -> ContactFieldType {
        first.map(ContactFieldType.init(raw:)) ?? .custom("")
    }
}
