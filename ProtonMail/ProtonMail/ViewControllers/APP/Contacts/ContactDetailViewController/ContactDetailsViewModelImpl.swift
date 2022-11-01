//
//  ContactDetailsViewModelImpl.swift
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

import Foundation
import PromiseKit
import Crypto
import CoreData
import OpenPGP
import ProtonCore_DataModel
import ProtonCore_Payments

class ContactDetailsViewModelImpl: ContactDetailsViewModel {

    private let contactService: ContactDataService
    private var contactParser: ContactParserProtocol!

    private var origEmails: [ContactEditEmail] = []
    private var origAddresses: [ContactEditAddress] = []
    private var origTelephons: [ContactEditPhone] = []
    private var origInformations: [ContactEditInformation] = []
    private var origFields: [ContactEditField] = []
    private var origNotes: [ContactEditNote] = []
    private var origUrls: [ContactEditUrl] = []
    private var profilePicture: UIImage?

    private var verifyType2: Bool = true
    private var verifyType3: Bool = true

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
        .url,
        .information,
        .custom_field,
        .notes,
        .share
    ]

    private let contactFetchedController: NSFetchedResultsController<Contact>

    init(contact: ContactEntity, user: UserManager, coreDateService: CoreDataService) {
        self.contactService = user.contactService
        contactFetchedController = contactService.contactFetchedController(by: contact.contactID)

        super.init(user: user, coreDataService: coreDateService, contact: contact)
        self.contactParser = ContactParser(resultDelegate: self)

        contactFetchedController.delegate = self
        try? contactFetchedController.performFetch()
    }

    override func sections() -> [ContactEditSectionType] {
        return typeSection
    }

    override func statusType2() -> Bool {
        return verifyType2
    }

    override func statusType3() -> Bool {
        return verifyType3
    }

    override func type3Error() -> Bool {
        return self.decryptError
    }

    override func debugging() -> Bool {
        return false
    }

    override func hasEncryptedContacts() -> Bool {
        if self.type3Error() {
            return true
        }

        if !self.statusType3() {
            return true
        }

        if self.getPhones().count > 0 {
            return true
        }
        if self.getAddresses().count > 0 {
            return true
        }
        if self.getInformations().count > 0 {
            return true
        }
        if self.getFields().count > 0 {
            return true
        }
        if self.getNotes().count > 0 {
            return true
        }
        if self.getUrls().count > 0 {
            return true
        }

        if !paidUser() {
            return true
        }

        return false
    }

    @discardableResult
    override func rebuild() -> Bool {
        if self.contact.needsRebuild {
            origEmails = []
            origAddresses = []
            origTelephons = []
            origInformations = []
            origFields = []
            origNotes = []
            origUrls = []
            profilePicture = nil

            verifyType2 = true
            verifyType3 = true
            self.setupEmails()
            return true
        }
        return false
    }

    private func rebuildData() {
        origEmails = []
        origAddresses = []
        origTelephons = []
        origInformations = []
        origFields = []
        origNotes = []
        origUrls = []
        profilePicture = nil

        verifyType2 = true
        verifyType3 = true
        self.setupEmails(forceRebuild: true)
    }

    @discardableResult
    private func setupEmails(forceRebuild: Bool = false) -> Promise<Void> {
        return firstly { () -> Promise<Void> in
            let userInfo = self.user.userInfo

            //  origEmails
            let cards = self.contact.cardDatas
            for card in cards.sorted(by: {$0.type.rawValue < $1.type.rawValue}) {
                switch card.type {
                case .PlainText:
                    self.contactParser
                        .parsePlainTextContact(data: card.data,
                                               coreDataService: self.coreDataService,
                                               contactID: self.contact.contactID)
                case .EncryptedOnly:
                    try self.contactParser
                        .parseEncryptedOnlyContact(card: card,
                                                   passphrase: user.mailboxPassword,
                                                   userKeys: userInfo.userKeys)
                case .SignedOnly:
                    self.verifyType2 = self.contactParser.verifySignature(
                        signature: card.sign,
                        plainText: card.data,
                        userKeys: userInfo.userKeys,
                        passphrase: user.mailboxPassword)
                    self.contactParser
                        .parsePlainTextContact(data: card.data,
                                               coreDataService: self.coreDataService,
                                               contactID: self.contact.contactID)
                case .SignAndEncrypt:
                    try self.contactParser
                        .parseSignAndEncryptContact(card: card,
                                                    passphrase: user.mailboxPassword,
                                                    firstUserKey: userInfo.firstUserKey(),
                                                    userKeys: userInfo.userKeys)
                }
            }

            if !forceRebuild {
                self.updateRebuildFlag()
            }

            if self.origEmails.count == 0 {
                for (index, item) in self.typeSection.enumerated() {
                    if item == .email_header {
                        self.typeSection.remove(at: index)
                        break
                    }
                }
            }

            return Promise.value(())
        }
    }
    
    override func getDetails(loading: () -> Void) -> Promise<Void> {
        if contact.isDownloaded && contact.needsRebuild == false {
            return firstly {
                self.setupEmails()
            }.then {
                return Promise.value
            }
        }
        loading()
        return self.updateContactDetail()
    }

    override func getProfile() -> ContactEditProfile {
        return ContactEditProfile(n_displayname: contact.name, isNew: false)
    }

    override func getProfilePicture() -> UIImage? {
        return self.profilePicture
    }

    override func getEmails() -> [ContactEditEmail] {
        return self.origEmails
    }

    override func getPhones() -> [ContactEditPhone] {
        return self.origTelephons
    }

    override func getAddresses() -> [ContactEditAddress] {
        return self.origAddresses
    }

    override func getInformations() -> [ContactEditInformation] {
        return self.origInformations
    }

    override func getFields() -> [ContactEditField] {
        return self.origFields
    }

    override func getNotes() -> [ContactEditNote] {
        return self.origNotes
    }

    override func getUrls() -> [ContactEditUrl] {
        return self.origUrls
    }
    
    override func getContact() -> ContactEntity {
        return contact
    }

    override func export() -> String {
        let cards = self.contact.cardDatas
        var vcard: PMNIVCard? = nil
        let userInfo = self.user.userInfo
        for card in cards {
            if card.type == .SignAndEncrypt {
                var pt_contact: String?
                let userkeys = userInfo.userKeys
                for key in userkeys {
                    do {
                        pt_contact = try? card.data.decryptMessageWithSingleKeyNonOptional(key.privateKey,
                                                                                           passphrase: user.mailboxPassword)
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

    override func exportName() -> String {
        let name = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            return name + ".vcf"
        }
        return "exported.vcf"
    }
}

// MARK: CoreData related
extension ContactDetailsViewModelImpl: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let object = self.getContactObject() {
            self.setContact(ContactEntity(contact: object))
        }
        rebuildData()
        reloadView?()
    }

    private func updateRebuildFlag() {
        let objectID = self.contact.objectID.rawValue
        self.coreDataService.rootSavingContext.performAndWait { [weak self] in
            if let contactToUpdate = try? self?.coreDataService.rootSavingContext.existingObject(with: objectID) as? Contact {
                contactToUpdate.needsRebuild = false
                _ = self?.coreDataService.rootSavingContext.saveUpstreamIfNeeded()
            }
        }
    }

    private func updateContactDetail() -> Promise<Void> {
        let contactID = self.contact.contactID.rawValue
        return Promise { [weak self] seal in
            guard let self = self else { return }
            self.contactService.details(contactID: contactID).then { contactObject -> Promise<Void> in
                self.setContact(contactObject)
                return self.setupEmails()
            }.done {
                seal.fulfill_()
            }.catch { (error) in
                seal.reject(error)
            }
        }
    }

    private func getContactObject() -> Contact? {
        self.contactFetchedController.fetchedObjects?.first
    }
}

extension ContactDetailsViewModelImpl: ContactParserResultDelegate {
    func append(emails: [ContactEditEmail]) {
        self.origEmails.append(contentsOf: emails)
    }

    func append(addresses: [ContactEditAddress]) {
        self.origAddresses.append(contentsOf: addresses)
    }

    func append(telephones: [ContactEditPhone]) {
        self.origTelephons.append(contentsOf: telephones)
    }

    func append(informations: [ContactEditInformation]) {
        self.origInformations.append(contentsOf: informations)
    }

    func append(fields: [ContactEditField]) {
        self.origFields.append(contentsOf: fields)
    }

    func append(notes: [ContactEditNote]) {
        self.origNotes.append(contentsOf: notes)
    }

    func append(urls: [ContactEditUrl]) {
        self.origUrls.append(contentsOf: urls)
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
