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

    private let cards: [CardData]
    private var cardObjects: [CardObject] = []
    private let userKeys: [ArmoredKey]
    private let mailboxPassphrase: Passphrase

    /// - Parameters:
    ///   - cards: In Proton contact data is stored in multiple vCards. `cards` is the collection of vCards that represent a single contact
    ///   - userKeys: User keys that will be used to try to decrypt and verify vCards depending on `CardDataType`
    ///   - mailboxPassphrase: User's mailbox pasphrase used to decrypt and verify vCards  depending on `CardDataType`
    init(cards: [CardData], userKeys: [ArmoredKey], mailboxPassphrase: Passphrase) {
        self.cards = cards
        self.userKeys = userKeys
        self.mailboxPassphrase = mailboxPassphrase
    }

    /// Call this function before trying to access the vCard fields
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
            return CardObject(type: card.type, object: VCardObject(object: pmniCard))
        }
    }
}

// MARK: read contact fields

extension ProtonVCards {

    func name(fromCardOfType type: CardDataType = .PlainText) -> ContactField.Name {
        guard let card = cardObjects.first(where: { $0.type == type }) else {
            return ContactField.Name(firstName: "", lastName: "")
        }
        return card.object.name()
    }

    func formattedName(fromCardOfType type: CardDataType = .PlainText) -> String {
        guard let card = cardObjects.first(where: { $0.type == type }) else { return "" }
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
    
    /// Replaces the emails of the signed card which is where emails should be according to Proton specs
    func replaceEmails(with emails: [ContactField.Email]) throws {
        cardObjects
            .first(where: { $0.type == .SignedOnly })?
            .object
            .replaceEmails(with: emails)
    }
}

// MARK: methods to obtain a PMNIVCard object

extension ProtonVCards {

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
    case expectedVCardNotFound
}
