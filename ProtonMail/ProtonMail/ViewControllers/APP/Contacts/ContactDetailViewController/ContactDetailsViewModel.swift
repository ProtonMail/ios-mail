//
//  ContactDetailsViewModel.swift
//  Proton Mail - Created on 5/2/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Combine
import CoreData
import Foundation
import ProtonCoreCrypto
import ProtonCoreDataModel
import UIKit
import VCard

final class ContactDetailsViewModel: NSObject {
    private var contactParser: ContactParserProtocol?

    private(set) var emails: [ContactEditEmail] = []
    private(set) var addresses: [ContactEditAddress] = []
    private(set) var phones: [ContactEditPhone] = []

    private(set) var birthday: ContactEditInformation?
    private(set) var organizations: [ContactEditInformation] = []
    private(set) var nickNames: [ContactEditInformation] = []
    private(set) var titles: [ContactEditInformation] = []
    private(set) var gender: ContactEditInformation?
    private(set) var anniversary: ContactEditInformation?

    private(set) var fields: [ContactEditField] = []
    private(set) var notes: [ContactEditNote] = []
    private(set) var urls: [ContactEditUrl] = []
    private(set) var profilePicture: UIImage?

    private(set) var verifyType2: Bool = true
    private(set) var verifyType3: Bool = true

    private var decryptError: Bool = false

    private var typeSection: [ContactEditSectionType] = [
        .email_header,
        .type2_warning,
        .emails,
        .encrypted_header,
        .type3_error,
        .type3_warning,
        .cellphone,
        .home_address,
        .birthday,
        .url,
        .organization,
        .nickName,
        .title,
        .gender,
        .anniversary,
        .custom_field,
        .notes
    ]

    var reloadView: (() -> Void)?

    private let dataPublisher: ContactPublisher
    private var cancellable: AnyCancellable?
    let dependencies: Dependencies
    private(set) var contact: ContactEntity

    init(
        contact: ContactEntity,
        dependencies: Dependencies
    ) {
        self.contact = contact
        self.dependencies = dependencies
        dataPublisher = .init(
            contextProvider: dependencies.coreDataService,
            contactID: contact.contactID
        )
        super.init()
        self.contactParser = ContactParser(resultDelegate: self)
        cancellable = dataPublisher.contentDidChange
            .map{ $0.map { ContactEntity(contact: $0) }}
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] contacts in
                guard let contact = contacts.first else { return }
                self?.setContact(contact)
                self?.rebuildData()
                self?.reloadView?()
            })
        dataPublisher.start()
    }

    func sections() -> [ContactEditSectionType] {
        return typeSection
    }

    func type3Error() -> Bool {
        return self.decryptError
    }

    @discardableResult
    func rebuild() -> Bool {
        if self.contact.needsRebuild {
            clearAddData()
            try? setupEmails()
            return true
        }
        return false
    }

    private func clearAddData() {
        emails = []
        addresses = []
        phones = []
        fields = []
        notes = []
        urls = []
        profilePicture = nil
        birthday = nil
        organizations = []
        nickNames = []
        titles = []
        gender = nil
        anniversary = nil

        verifyType2 = true
        verifyType3 = true
    }

    private func rebuildData() {
        clearAddData()
        try?setupEmails(forceRebuild: true)
    }

    private func setupEmails(forceRebuild: Bool = false) throws {
        let userInfo = self.dependencies.user.userInfo

        //  origEmails
        let cards = self.contact.cardDatas
        for card in cards.sorted(by: { $0.type.rawValue < $1.type.rawValue }) {
            switch card.type {
            case .PlainText:
                self.contactParser?
                    .parsePlainTextContact(data: card.data,
                                           contextProvider: self.dependencies.coreDataService,
                                           contactID: self.contact.contactID)
            case .EncryptedOnly:
                try self.contactParser?
                    .parseEncryptedOnlyContact(card: card,
                                               passphrase: dependencies.user.mailboxPassword,
                                               userKeys: userInfo.userKeys.toArmoredPrivateKeys)
            case .SignedOnly:
                self.verifyType2 = self.contactParser?.verifySignature(
                    signature: ArmoredSignature(value: card.signature),
                    plainText: card.data,
                    userKeys: userInfo.userKeys.toArmoredPrivateKeys,
                    passphrase: dependencies.user.mailboxPassword
                ) ?? false
                self.contactParser?
                    .parsePlainTextContact(data: card.data,
                                           contextProvider: self.dependencies.coreDataService,
                                           contactID: self.contact.contactID)
            case .SignAndEncrypt:
                try self.contactParser?
                    .parseSignAndEncryptContact(
                        card: card,
                        passphrase: dependencies.user.mailboxPassword,
                        firstUserKey: userInfo.firstUserKey().map { ArmoredKey(value: $0.privateKey) },
                        userKeys: userInfo.userKeys.toArmoredPrivateKeys
                    )
            }
        }

        if !forceRebuild {
            self.updateRebuildFlag()
        }

        if self.emails.count == 0 {
            for (index, item) in self.typeSection.enumerated() {
                if item == .email_header {
                    self.typeSection.remove(at: index)
                    break
                }
            }
        }
    }

    @MainActor
    func getDetails(loading: () -> Void) async throws {
        if contact.isDownloaded && contact.needsRebuild == false {
            try setupEmails()
        } else {
            loading()
            try await updateContactDetail()
        }
    }

    func getProfile() -> ContactEditProfile {
        return ContactEditProfile(n_displayname: contact.name, isNew: false)
    }

    func export() -> String {
        let cards = self.contact.cardDatas
        var vcard: PMNIVCard? = nil
        let userInfo = dependencies.user.userInfo
        for card in cards {
            if card.type == .SignAndEncrypt {
                var pt_contact: String?
                let userkeys = userInfo.userKeys
                for key in userkeys {
                    do {
                        pt_contact = try? card.data.decryptMessageWithSingleKeyNonOptional(ArmoredKey(value: key.privateKey),
                                                                                           passphrase: dependencies.user.mailboxPassword)
                        break
                    }
                }

                guard let pt_contact_vcard = pt_contact else {
                    break
                }
                vcard = PMNIEzvcard.parseFirst(pt_contact_vcard)
            }
        }

        for cardData in cards {
            if cardData.type == .PlainText {
                if let card = PMNIEzvcard.parseFirst(cardData.data) {
                    let emails = card.getEmails()
                    let formattedName = card.getFormattedName()
                    if vcard != nil {
                        vcard!.setEmails(emails)
                        vcard!.setFormattedName(formattedName)
                    } else {
                        vcard = card
                    }
                }
            }
        }

        for cardData in cards {
            if cardData.type == .SignedOnly {
                if let card = PMNIEzvcard.parseFirst(cardData.data) {
                    let emails = card.getEmails()
                    let formattedName = card.getFormattedName()
                    if vcard != nil {
                        vcard!.setEmails(emails)
                        vcard!.setFormattedName(formattedName)
                    } else {
                        vcard = card
                    }
                }
            }
        }

        guard let outVCard = vcard else {
            return ""
        }

        return PMNIEzvcard.write(outVCard)
    }

    func exportName() -> String {
        let name = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            return name + ".vcf"
        }
        return "exported.vcf"
    }

    func setContact(_ contact: ContactEntity) {
        self.contact = contact
    }
}

extension ContactDetailsViewModel{
    private func updateRebuildFlag() {
        let objectID = self.contact.objectID.rawValue
        dependencies.coreDataService.performAndWaitOnRootSavingContext { context in
            if let contactToUpdate = try? context.existingObject(with: objectID) as? Contact {
                contactToUpdate.needsRebuild = false
                _ = context.saveUpstreamIfNeeded()
            }
        }
    }

    @MainActor
    private func updateContactDetail() async throws {
        let contact = try await dependencies.contactService.fetchContact(contactID: contact.contactID)
        setContact(contact)
        try setupEmails()
    }
}

extension ContactDetailsViewModel: ContactParserResultDelegate {
    func append(structuredName: ContactEditStructuredName) {
        // TODO: show structuredName
    }

    func append(emails: [ContactEditEmail]) {
        self.emails.append(contentsOf: emails)
    }

    func append(addresses: [ContactEditAddress]) {
        self.addresses.append(contentsOf: addresses)
    }

    func append(telephones: [ContactEditPhone]) {
        self.phones.append(contentsOf: telephones)
    }

    func append(informations: [ContactEditInformation]) {
        for info in informations {
            switch info.infoType {
            case .gender:
                gender = info
            case .birthday:
                birthday = info
            case .title:
                titles.append(info)
            case .organization:
                organizations.append(info)
            case .nickname:
                nickNames.append(info)
            case .anniversary:
                anniversary = info
            case .url:
                fatalError("Should not reach here")
            }
        }
    }

    func append(fields: [ContactEditField]) {
        self.fields.append(contentsOf: fields)
    }

    func append(notes: [ContactEditNote]) {
        self.notes.append(contentsOf: notes)
    }

    func append(urls: [ContactEditUrl]) {
        self.urls.append(contentsOf: urls)
    }

    func update(verifyType3: Bool) {
        self.verifyType3 = verifyType3
    }

    func update(decryptionError: Bool) {
        self.decryptError = decryptionError
    }

    func update(profilePicture: UIImage?) {
        self.profilePicture = profilePicture
    }
}

extension ContactDetailsViewModel {
    struct Dependencies {
        let user: UserManager
        let coreDataService: CoreDataContextProviderProtocol
        let contactService: ContactProviderProtocol
    }
}
