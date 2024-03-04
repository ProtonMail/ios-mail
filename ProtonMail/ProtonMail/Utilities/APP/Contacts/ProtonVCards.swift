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

final class ProtonVCards {
    private struct CardObject {
        let type: CardDataType
        let object: VCardObject
    }

    private let originalCards: [CardData]
    private var cardObjects: [CardObject] = []
    private let userKeys: [ArmoredKey]
    private let mailboxPassphrase: Passphrase

    /// - Parameters:
    ///   - cards: In Proton contact data is stored in multiple vCards. `cards` is the collection of vCards that represent a single contact
    ///   - userKeys: User keys that will be used to try to decrypt and verify vCards depending on `CardDataType`
    ///   - mailboxPassphrase: User's mailbox pasphrase used to decrypt and verify vCards  depending on `CardDataType`
    init(cards: [CardData], userKeys: [ArmoredKey], mailboxPassphrase: Passphrase) {
        self.originalCards = cards
        self.userKeys = userKeys
        self.mailboxPassphrase = mailboxPassphrase
    }

    /// Call this function before trying to access the vCard fields to decrypt and verify the signature
    func read() throws {
        try validateCardDataTypeUniqueness(cards: originalCards)
        cardObjects = try originalCards.map { card in
            let pmniCard: PMNIVCard
            switch card.type {
            case .PlainText:
                pmniCard = try parse(card: card)
            case .EncryptedOnly:
                pmniCard = try decryptAndParse(encryptedCard: card)
            case .SignedOnly:
                pmniCard = try verifyAndParse(signedCard: card)
            case .SignAndEncrypt:
                pmniCard = try decryptVerifyAndParse(encryptedAndSignedCard: card)
            }
            return CardObject(type: card.type, object: VCardObject(object: pmniCard))
        }
    }

    /// Validates that there is no more than one card for each CardDataType to verify this is a valid Proton contact
    private func validateCardDataTypeUniqueness(cards: [CardData]) throws {
        let duplicateCardType = Dictionary(grouping: cards, by: \.type).filter { $1.count > 1 }.keys
        guard duplicateCardType.isEmpty else {
            throw ProtonVCardsError.foundDuplicatedCardDataTypes
        }
    }

    /// Call this function when you want to get the latest data signed and encrypted into an array of `CardData`
    func write(userKey: Key, mailboxPassphrase: Passphrase) throws -> [CardData] {
        guard let signedOnlyCardObject = cardObject(ofType: .SignedOnly)?.object else {
            throw ProtonVCardsError.vCardOfTypeSignedOnlyNotFound
        }
        guard let signedCard = AppleContactParser.createCard2(
            by: signedOnlyCardObject.object,
            uuid: signedOnlyCardObject.object.getUid(),
            userKey: userKey,
            passphrase: mailboxPassphrase
        ) else {
            throw ProtonVCardsError.failedWritingSignedCardData
        }

        guard let signedAndEncryptedCardObject = cardObject(ofType: .SignAndEncrypt)?.object else {
            throw ProtonVCardsError.vCardOfTypeSignAndEncryptNotFound
        }
        guard let encryptedAndSignedCard = AppleContactParser.createCard3(
            by: signedAndEncryptedCardObject.object,
            userKey: userKey,
            passphrase: mailboxPassphrase,
            uuid: signedAndEncryptedCardObject.object.getUid()
        ) else {
            throw ProtonVCardsError.failedWritingSignedCardData
        }

        let originalDataDict = Dictionary(grouping: originalCards, by: \.type)
        let result: [CardData] = [
            originalDataDict[.PlainText]?.first,
            originalDataDict[.EncryptedOnly]?.first,
            signedCard,
            encryptedAndSignedCard
        ].compactMap { $0 }

        return result
    }

    private func cardObject(ofType type: CardDataType) -> CardObject? {
        guard let cardObject = cardObjects.first(where: { $0.type == type }) else { return nil }
        return cardObject
    }
}

// MARK: read contact fields

extension ProtonVCards {

    func name(fromCardOfType type: CardDataType = .SignAndEncrypt) -> ContactField.Name {
        guard let card = cardObject(ofType: type) else {
            return ContactField.Name(firstName: "", lastName: "")
        }
        return card.object.name()
    }

    func formattedName(fromCardOfType type: CardDataType = .SignedOnly) -> String {
        guard let card = cardObject(ofType: type) else { return "" }
        return card.object.formattedName()
    }

    func emails(fromCardTypes cardTypes: [CardDataType] = [.SignedOnly]) -> [ContactField.Email] {
        cardObjects
            .filter { cardTypes.contains($0.type) }
            .map(\.object)
            .flatMap {
                $0.emails()
            }
    }

    func addresses(fromCardTypes cardTypes: [CardDataType] = [.SignAndEncrypt]) -> [ContactField.Address] {
        cardObjects
            .filter { cardTypes.contains($0.type) }
            .map(\.object)
            .flatMap {
                $0.addresses()
            }
    }

    func phoneNumbers(fromCardTypes cardTypes: [CardDataType] = [.SignAndEncrypt]) -> [ContactField.PhoneNumber] {
        cardObjects
            .filter { cardTypes.contains($0.type) }
            .map(\.object)
            .flatMap {
                $0.phoneNumbers()
            }
    }

    func urls(fromCardTypes cardTypes: [CardDataType] = [.SignAndEncrypt]) -> [ContactField.Url] {
        cardObjects
            .filter { cardTypes.contains($0.type) }
            .map(\.object)
            .flatMap {
                $0.urls()
            }
    }

    func otherInfo(
        infoType: InformationType,
        fromCardTypes cardTypes: [CardDataType] = [.SignAndEncrypt]
    ) -> [ContactField.OtherInfo] {
        cardObjects
            .filter { cardTypes.contains($0.type) }
            .map(\.object)
            .flatMap {
                $0.otherInfo(infoType: infoType)
            }
    }
}

// MARK: read contact fields

extension ProtonVCards {

    func replaceName(with name: ContactField.Name) {
        cardObject(ofType: .SignAndEncrypt)?.object.replaceName(with: name)
    }

    func replaceFormattedName(with name: String) {
        cardObject(ofType: .SignedOnly)?.object.replaceFormattedName(with: name)
    }

    /// Replaces the emails of the signed card which is where they should be according to Proton specs
    func replaceEmails(with emails: [ContactField.Email]) {
        cardObject(ofType: .SignedOnly)?.object.replaceEmails(with: emails)
    }

    /// Replaces the addresses of the encrypted card which is where they should be according to Proton specs
    func replaceAddresses(with addresses: [ContactField.Address]) {
        cardObject(ofType: .SignAndEncrypt)?.object.replaceAddresses(with: addresses)
    }

    /// Replaces the phone numbers of the encrypted card which is where they should be according to Proton specs
    func replacePhoneNumbers(with phoneNumbers: [ContactField.PhoneNumber]) {
        cardObject(ofType: .SignAndEncrypt)?.object.replacePhoneNumbers(with: phoneNumbers)
    }

    /// Replaces the urls of the encrypted card which is where they should be according to Proton specs
    func replaceUrls(with urls: [ContactField.Url]) {
        cardObject(ofType: .SignAndEncrypt)?.object.replaceUrls(with: urls)
    }

    /// Replaces the urls of the encrypted card which is where they should be according to Proton specs
    func replaceOtherInfo(infoType: InformationType, with info: [ContactField.OtherInfo]) {
        cardObject(ofType: .SignAndEncrypt)?.object.replaceOtherInfo(infoType: infoType, with: info)
    }
}

// MARK: methods to obtain a PMNIVCard object

extension ProtonVCards {

    private func parseVCard(_ card: String) throws -> PMNIVCard {
        guard let parsedObject = PMNIEzvcard.parseFirst(card) else { throw ProtonVCardsError.failedParsingVCardString }
        return parsedObject
    }

    private func parse(card: CardData) throws -> PMNIVCard {
        return try parseVCard(card.data)
    }

    private func decryptAndParse(encryptedCard: CardData) throws -> PMNIVCard {
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

extension ProtonVCards {

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
            throw ProtonVCardsError.failedVerifyingCard
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
            throw ProtonVCardsError.failedDecryptingVCard
        }
        return decryptedText
    }
}

enum ProtonVCardsError: Error {
    case foundDuplicatedCardDataTypes
    case failedParsingVCardString
    case failedDecryptingVCard
    case failedVerifyingCard
    case vCardOfTypeSignedOnlyNotFound
    case vCardOfTypeSignAndEncryptNotFound
    case failedWritingSignedCardData
    case failedWritingEncryptedAndSignedCardData
}
