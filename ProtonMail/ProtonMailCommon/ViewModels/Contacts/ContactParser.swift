// Copyright (c) 2021 Proton AG
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
import OpenPGP
import ProtonCore_DataModel

struct ContactDecryptionResult {
    let decryptedText: String?
    let signKey: Key?
    let decryptError: Bool
}

protocol ContactParserResultDelegate: AnyObject {
    func append(emails: [ContactEditEmail])
    func append(addresses: [ContactEditAddress])
    func append(telephones: [ContactEditPhone])
    func append(informations: [ContactEditInformation])
    func append(fields: [ContactEditField])
    func append(notes: [ContactEditNote])
    func append(urls: [ContactEditUrl])

    func update(verifyType3: Bool)
    func update(decryptionError: Bool)
    func update(profilePicture: UIImage?)
}

protocol ContactParserProtocol {
    func parsePlainTextContact(data: String, coreDataService: CoreDataService, contactID: String)
    func parseEncryptedOnlyContact(card: CardData, passphrase: String, userKeys: [Key]) throws
    func parseSignAndEncryptContact(card: CardData,
                                    passphrase: String,
                                    firstUserKey: Key?,
                                    userKeys: [Key]) throws
    func verifySignature(signature: String,
                         plainText: String,
                         userKeys: [Key],
                         passphrase: String) -> Bool
}

final class ContactParser: ContactParserProtocol {
    private enum ParserError: Error {
        case decryptionFailed
        case userKeyNotProvided
    }

    private weak var resultDelegate: ContactParserResultDelegate?

    init(resultDelegate: ContactParserResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    func parsePlainTextContact(data: String, coreDataService: CoreDataService, contactID: String) {
        guard let vCard = PMNIEzvcard.parseFirst(data) else { return }

        let emails = vCard.getEmails()
        var order: Int = 1
        var contactEmails: [ContactEditEmail] = []
        for email in emails {
            let types = email.getTypes()
            let typeRaw = types.isEmpty ? "": (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)

            let object = ContactEditEmail(order: order,
                                          type: type == .empty ? .email : type,
                                          email: email.getValue(),
                                          isNew: false,
                                          keys: nil,
                                          contactID: contactID,
                                          encrypt: nil,
                                          sign: nil ,
                                          scheme: nil,
                                          mimeType: nil,
                                          delegate: nil,
                                          coreDataService: coreDataService)
            contactEmails.append(object)
            order += 1
        }
        self.resultDelegate?.append(emails: contactEmails)
    }

    func parseEncryptedOnlyContact(card: CardData, passphrase: String, userKeys: [Key]) throws {
        let decryptionResult = self.decryptMessage(encryptedText: card.data,
                                                   passphrase: passphrase,
                                                   userKeys: userKeys)
        self.resultDelegate?.update(decryptionError: decryptionResult.decryptError)
        guard let decryptedText = decryptionResult.decryptedText else {
            throw ParserError.decryptionFailed
        }
        try self.parseDecryptedContact(data: decryptedText)
    }

    func parseSignAndEncryptContact(card: CardData,
                                    passphrase: String,
                                    firstUserKey: Key?,
                                    userKeys: [Key]) throws {
        guard let firstUserKey = firstUserKey else {
            throw ParserError.userKeyNotProvided
        }

        let decryptionResult = self.decryptMessage(encryptedText: card.data,
                                                   passphrase: passphrase,
                                                   userKeys: userKeys)
        self.resultDelegate?.update(decryptionError: decryptionResult.decryptError)
        let key = decryptionResult.signKey ?? firstUserKey
        guard let decryptedText = decryptionResult.decryptedText else {
            throw ParserError.decryptionFailed
        }

        let verifyType3 = self.verifyDetached(signature: card.sign,
                                              plainText: decryptedText,
                                              key: key)
        self.resultDelegate?.update(verifyType3: verifyType3)

        try self.parseDecryptedContact(data: decryptedText)
    }

    func verifySignature(signature: String,
                         plainText: String,
                         userKeys: [Key],
                         passphrase: String) -> Bool {
        var isVerified = true
        for key in userKeys {
            do {
                isVerified = try Crypto().verifyDetached(signature: signature,
                                                         plainText: plainText,
                                                         publicKey: key.publicKey,
                                                         verifyTime: 0)

                guard isVerified else { continue }
                if !key.privateKey.check(passphrase: passphrase) {
                    isVerified = false
                }
                return isVerified
            } catch {
                isVerified = false
            }
        }
        // Should be false
        return isVerified
    }
}

// MARK: Decrypted contact
// Private functions
extension ContactParser {
    enum VCardTypes: String {
        case telephone = "Telephone"
        case address = "Address"
        case organization = "Organization"
        case title = "Title"
        case nickname = "Nickname"
        case birthday = "Birthday"
        case anniversary = "Anniversary"
        case gender = "Gender"
        case url = "Url"
        case photo = "Photo"
    }

    private func verifyDetached(signature: String, plainText: String, key: Key) -> Bool {
        do {
            let verifyStatus = try Crypto().verifyDetached(signature: signature,
                                                           plainText: plainText,
                                                           publicKey: key.publicKey,
                                                           verifyTime: 0)
            return verifyStatus
        } catch {
            return false
        }
    }

    private func decryptMessage(encryptedText: String,
                                passphrase: String,
                                userKeys: [Key]) -> ContactDecryptionResult {
        var decryptedText: String?
        var signKey: Key?
        var decryptError = false
        for key in userKeys {
            do {
                decryptedText = try encryptedText.decryptMessageWithSinglKey(key.privateKey,
                                                                             passphrase: passphrase)
                signKey = key
                decryptError = false
                break
            } catch {
                decryptError = true
            }
        }
        return ContactDecryptionResult(decryptedText: decryptedText, signKey: signKey, decryptError: decryptError)
    }

    private func parseDecryptedContact(data: String) throws {
        try ObjC.catchException { [weak self] in
            guard let self = self,
                  let vCard = PMNIEzvcard.parseFirst(data) else { return }
            self.parse(types: vCard.getPropertyTypes(), vCard: vCard)
            self.parse(customs: vCard.getCustoms())
            self.parse(note: vCard.getNote())
        }
    }

    private func parse(types: [String], vCard: PMNIVCard) {
        for type in types {
            guard let vCardType = VCardTypes(rawValue: type) else { continue }
            switch vCardType {
            case .telephone:
                self.parse(telephones: vCard.getTelephoneNumbers())
            case .address:
                self.parse(addresses: vCard.getAddresses())
            case .organization:
                self.parse(organization: vCard.getOrganization())
            case .title:
                self.parse(title: vCard.getTitle())
            case .nickname:
                self.parse(nickName: vCard.getNickname())
            case .birthday:
                self.parse(birthdays: vCard.getBirthdays())
            case .anniversary:
                break
            case .gender:
                self.parse(gender: vCard.getGender())
            case .url:
                self.parse(urls: vCard.getUrls())
            case .photo:
                self.parse(photo: vCard.getPhoto())
            }
        }
    }

    private func parse(telephones: [PMNITelephone]) {
        var order = 1
        var contactTelephones: [ContactEditPhone] = []
        for phone in telephones {
            let types = phone.getTypes()
            let typeRaw = types.isEmpty ? "": (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditPhone = ContactEditPhone(
                order: order,
                type: type == .empty ? .phone : type,
                phone: phone.getText(),
                isNew: false
            )
            contactTelephones.append(contactEditPhone)
            order += 1
        }
        self.resultDelegate?.append(telephones: contactTelephones)
    }

    private func parse(addresses: [PMNIAddress]) {
        var order = 1
        var results: [ContactEditAddress] = []
        for address in addresses {
            let types = address.getTypes()
            let typeRaw = types.isEmpty ? "": (types.first ?? "")
            let type = ContactFieldType.get(raw: typeRaw)

            let pobox = address.getPoBoxes().asCommaSeparatedList(trailingSpace: false)
            let street = address.getStreetAddress()
            let extended = address.getExtendedAddress()
            let locality = address.getLocality()
            let region = address.getRegion()
            let postal = address.getPostalCode()
            let country = address.getCountry()

            let contactEditAddress = ContactEditAddress(
                order: order,
                type: type == .empty ? .address : type,
                pobox: pobox,
                street: street,
                streetTwo: extended,
                locality: locality,
                region: region,
                postal: postal,
                country: country,
                isNew: false
            )
            results.append(contactEditAddress)
            order += 1
        }
        self.resultDelegate?.append(addresses: results)
    }

    private func parse(organization: PMNIOrganization?) {
        let contactEditInformation = ContactEditInformation(
            type: .organization,
            value: organization?.getValue() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(title: PMNITitle?) {
        let info = ContactEditInformation(
            type: .title,
            value: title?.getTitle() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [info])
    }

    private func parse(nickName: PMNINickname?) {
        let contactEditInformation = ContactEditInformation(
            type: .nickname,
            value: nickName?.getNickname() ?? "",
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(birthdays: [PMNIBirthday]) {
        let contactEditInformations = birthdays.map { birthday in
            ContactEditInformation(
                type: .birthday,
                value: birthday.formattedBirthday,
                isNew: false
            )
        }
        self.resultDelegate?.append(informations: contactEditInformations)
    }

    private func parse(gender: PMNIGender?) {
        guard let gender = gender else { return }
        let contactEditInformation = ContactEditInformation(
            type: .gender,
            value: gender.getGender(),
            isNew: false
        )
        self.resultDelegate?.append(informations: [contactEditInformation])
    }

    private func parse(urls: [PMNIUrl]) {
        var order = 1
        var results: [ContactEditUrl] = []
        for url in urls {
            let typeRaw = url.getType()
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditUrl = ContactEditUrl(
                order: order,
                type: type == .empty ? .url : type,
                url: url.getValue(),
                isNew: false
            )
            results.append(contactEditUrl)
            order += 1
        }
        self.resultDelegate?.append(urls: results)
    }

    private func parse(photo: PMNIPhoto?) {
        guard let photo = photo else { return }
        let rawData = photo.getRawData()
        self.resultDelegate?.update(profilePicture: UIImage(data: rawData))
    }

    private func parse(customs: [PMNIPMCustom]) {
        var order = 1
        var results: [ContactEditField] = []
        for custom in customs {
            let typeRaw = custom.getType()
            let type = ContactFieldType.get(raw: typeRaw)
            let contactEditField = ContactEditField(
                order: order,
                type: type,
                field: custom.getValue(),
                isNew: false
            )
            results.append(contactEditField)
            order += 1
        }
        self.resultDelegate?.append(fields: results)
    }

    private func parse(note: PMNINote?) {
        guard let note = note else { return }
        let contactEditNote = ContactEditNote(note: note.getNote(), isNew: false)
        contactEditNote.isNew = false
        self.resultDelegate?.append(notes: [contactEditNote])
    }
}
