//
//  ContactEditViewModelImpl.swift
//  Proton Mail - Created on 5/3/17.
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

import ProtonCoreCrypto
import UIKit
import VCard

// swiftlint:disable:next type_body_length
final class ContactEditViewModel {
    enum Constants {
        static let maximumDisplayNameLength = 190
        static let emptyDisplayNameError = -372
    }

    private let defaultSectionsInAddNewMenu: [InformationType] = [
        .url,
        .organization,
        .nickname,
        .title,
        .gender,
        .anniversary
    ]

    private(set) var sections: [ContactEditSectionType] = [
        .emails,
        .encrypted_header,
        .cellphone,
        .home_address,
        .birthday,
        .addNewField,
        .notes
    ]
    private var contactParser: ContactParserProtocol!
    private(set) var contactEntity: ContactEntity?

    var profilePicture: UIImage?
    var origProfilePicture: UIImage?
    var profile: ContactEditProfile = .init(n_displayname: "")
    var structuredName: ContactEditStructuredName?

    var emails: [ContactEditEmail] = []

    var cells: [ContactEditPhone] = []
    var addresses: [ContactEditAddress] = []
    var birthday: ContactEditInformation?

    var urls: [ContactEditUrl] = []
    var organizations: [ContactEditInformation] = []
    var nickNames: [ContactEditInformation] = []
    var contactTitles: [ContactEditInformation] = []
    var gender: ContactEditInformation?
    var anniversary: ContactEditInformation?

    var fields: [ContactEditField] = []
    var notes: [ContactEditNote] = []

    var contactGroupData: [String: (name: String, color: String, count: Int)] = [:]

    private var origvCard2: PMNIVCard?
    private var origvCard3: PMNIVCard?
    let dependencies: Dependencies

    init(
        contactEntity: ContactEntity?,
        dependencies: Dependencies
    ) {
        self.dependencies = dependencies
        self.contactEntity = contactEntity
        self.contactParser = ContactParser(resultDelegate: self)
        self.prepareContactData()
        self.prepareContactGroupData()
        updateSectionsData()
        sections.append(.delete)
    }

    init(
        contactVO: ContactVO,
        dependencies: Dependencies
    ) {
        self.dependencies = dependencies
        self.contactParser = ContactParser(resultDelegate: self)

        let email = newEmail()
        email.newEmail = contactVO.displayEmail ?? .empty

        profile.newDisplayName = contactVO.displayName ?? .empty
    }

    func getSections() -> [ContactEditSectionType] {
        return self.sections
    }

    func sectionCount() -> Int {
        return sections.count
    }

    func isNew() -> Bool {
        self.contactEntity == nil
    }

    func getEmails() -> [ContactEditEmail] {
        return emails
    }

    func getCells() -> [ContactEditPhone] {
        return cells
    }

    func getAddresses() -> [ContactEditAddress] {
        return addresses
    }

    func getFields() -> [ContactEditField] {
        return fields
    }

    func getNotes() -> [ContactEditNote] {
        if notes.isEmpty {
            notes.append(.init(note: "", isNew: true))
        }
        return notes
    }

    func getProfile() -> ContactEditProfile {
        return profile
    }

    func getProfilePicture() -> UIImage? {
        return self.profilePicture
    }

    func setProfilePicture(image: UIImage?) {
        self.profilePicture = image
    }

    func profilePictureNeedsUpdate() -> Bool {
        if let orig = self.origProfilePicture {
            return !orig.isEqual(self.profilePicture)
        } else {
            // orig is nil
            return self.profilePicture != nil
        }
    }

    func getUrls() -> [ContactEditUrl] {
        return urls
    }

    func newUrl() -> ContactEditUrl {
        let type = pick(newType: ContactFieldType.urlTypes, pickedTypes: urls)
        let url = ContactEditUrl(order: urls.count, type: type, url: "", isNew: true)
        urls.append(url)
        return url
    }

    func deleteUrl(at index: Int) {
        if urls.count > index {
            urls.remove(at: index)
        }
    }

    func newEmail() -> ContactEditEmail {
        let type = pick(newType: ContactFieldType.emailTypes, pickedTypes: emails)
        let email = ContactEditEmail(order: emails.count,
                                     type: type,
                                     email: "",
                                     isNew: true,
                                     keys: nil,
                                     contactID: self.contactEntity?.contactID.rawValue,
                                     encrypt: nil,
                                     sign: nil,
                                     scheme: nil,
                                     mimeType: nil,
                                     delegate: self,
                                     contextProvider: dependencies.contextProvider)
        emails.append(email)
        return email
    }

    func deleteEmail(at index: Int) {
        if emails.count > index {
            emails.remove(at: index)
        }
    }

    func newPhone() -> ContactEditPhone {
        let type = pick(newType: ContactFieldType.phoneTypes, pickedTypes: cells)
        let cell = ContactEditPhone(order: emails.count, type: type, phone: "", isNew: true)
        cells.append(cell)
        return cell
    }

    func deletePhone(at index: Int) {
        if cells.count > index {
            cells.remove(at: index)
        }
    }

    func newAddress() -> ContactEditAddress {
        let type = pick(newType: ContactFieldType.addrTypes, pickedTypes: addresses)
        let addr = ContactEditAddress(order: emails.count, type: type)
        addresses.append(addr)
        return addr
    }

    func deleteAddress(at index: Int) {
        if addresses.count > index {
            addresses.remove(at: index)
        }
    }

    func newField() -> ContactEditField {
        let type = pick(newType: ContactFieldType.fieldTypes, pickedTypes: fields)
        let field = ContactEditField(order: emails.count, type: type, field: "", isNew: true)
        fields.append(field)
        return field
    }

    func deleteField(at index: Int) {
        if fields.count > index {
            fields.remove(at: index)
        }
    }

    func deleteOrganization(at index: Int) {
        if organizations.count > index {
            organizations.remove(at: index)
        }
    }

    func deleteNickName(at index: Int) {
        if nickNames.count > index {
            nickNames.remove(at: index)
        }
    }

    func deleteTitle(at index: Int) {
        if contactTitles.count > index {
            contactTitles.remove(at: index)
        }
    }

    func setLastName(_ lastName: String) {
        if structuredName == nil {
            structuredName = .init(firstName: "", lastName: lastName, isCreatingContact: isNew())
        } else {
            structuredName?.lastName = lastName
        }
    }

    func setFirstName(_ firstName: String) {
        if structuredName == nil {
            structuredName = .init(firstName: firstName, lastName: "", isCreatingContact: isNew())
        } else {
            structuredName?.firstName = firstName
        }
    }

    typealias ContactEditSaveComplete = (_ error: NSError?) -> Void
    func done(complete: @escaping ContactEditSaveComplete) {
        for (index, mail) in self.emails.enumerated() {
            mail.update(order: index)
        }

        let completion = { (error: NSError?) in
            // The data merge to mainContext take some time
            // Delay for better UX
            delay(0.3) {
                if error == nil {
                    // we locally maintain the emailID by deleting all old ones
                    // and use the response to update the core data (see sharedContactDataService.update())
                    complete(nil)
                } else {
                    complete(error)
                }
            }
        }
        do {
            try displayNameValidationAndRecoverIfPossible()

            let cards = try prepareCardDatas()

            if let contact = contactEntity {
                dependencies.contactService.queueUpdate(
                    objectID: contact.objectID.rawValue,
                    cardDatas: cards,
                    newName: self.profile.newDisplayName,
                    emails: self.emails,
                    completion: completion
                )
            } else {
                let error = dependencies.contactService.queueAddContact(
                    cardDatas: cards,
                    name: self.profile.newDisplayName,
                    emails: self.emails,
                    importedFromDevice: false
                )
                complete(error)
            }
        } catch {
            complete(error as NSError)
        }
    }

    private func displayNameValidationAndRecoverIfPossible() throws {
        let newDisplayName = profile.newDisplayName.trim()
        let lastName = (structuredName?.lastName ?? "").trim()
        let firstName = (structuredName?.firstName ?? "").trim()

        if !isNew() && newDisplayName.isEmpty {
            profile.newDisplayName = ""
            throw NSError(
                domain: "ContactEdit",
                code: Constants.emptyDisplayNameError,
                localizedDescription: L10n.ContactEdit.emptyDisplayNameError
            )
        }
        guard newDisplayName.isEmpty else {
            try checkDisplayNameLength(displayName: newDisplayName)
            return
        }

        switch (firstName.isEmpty, lastName.isEmpty) {
        case (true, true):
            throw NSError(
                domain: "ContactEdit",
                code: Constants.emptyDisplayNameError,
                localizedDescription: L10n.ContactEdit.emptyDisplayNameError
            )
        default:
            let displayName = "\(firstName) \(lastName)".trim()
            try checkDisplayNameLength(displayName: displayName)
        }
    }

    private func checkDisplayNameLength(displayName: String) throws {
        profile.newDisplayName = displayName
        guard displayName.count > Constants.maximumDisplayNameLength else { return }
        throw NSError(
            domain: "ContactEdit",
            code: 998,
            userInfo: [
                NSLocalizedDescriptionKey: L10n.ContactEdit.contactNameTooLong,
                "displayName": displayName
            ]
        )
    }

    private func updateSectionsData() {
        guard let indexOfAddNewField = sections.firstIndex(of: .addNewField) else {
            return
        }
        if gender != nil {
            sections.insert(.gender, at: indexOfAddNewField)
        }
        if anniversary != nil {
            sections.insert(.anniversary, at: indexOfAddNewField)
        }
        if !urls.isEmpty {
            sections.insert(.url, at: indexOfAddNewField)
        }
        if !organizations.isEmpty {
            sections.insert(.organization, at: indexOfAddNewField)
        }
        if !contactTitles.isEmpty {
            sections.insert(.title, at: indexOfAddNewField)
        }
        if !nickNames.isEmpty {
            sections.insert(.nickName, at: indexOfAddNewField)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func prepareCardDatas() throws -> [CardData] {
        var cards: [CardData] = []

        // contact group, card type 0
        let vCard0 = PMNIVCard.createInstance()
        if let vCard0 = vCard0 {
            for (index, email) in getEmails().enumerated() {
                let group = "ITEM\(index + 1)"

                let newCategories = PMNICategories.createInstance(group,
                                                                  value: email.getContactGroupNames())
                vCard0.add(newCategories)
            }

            let vcard0Str = PMNIEzvcard.write(vCard0)
            let card0 = CardData(type: .PlainText,
                                 data: vcard0Str,
                                 signature: "")

            cards.append(card0)
        }

        if origvCard2 == nil {
            origvCard2 = PMNIVCard.createInstance()
        }

        let userInfo = dependencies.user.userInfo

        guard let userkey = userInfo.firstUserKey() else {
            throw NSError(
                domain: "",
                code: 999,
                localizedDescription: "User key not found"
            )
        }

        let signingKey = SigningKey(
            privateKey: ArmoredKey(value: userkey.privateKey),
            passphrase: dependencies.user.mailboxPassword
        )

        var uid: PMNIUid?
        if let vcard2 = origvCard2 {
            var defaultName = LocalString._general_unknown_title
            // TODO: need to check the old email's group id
            var newEmails: [PMNIEmail] = []
            vcard2.clearEmails()
            vcard2.clearKeys()
            vcard2.clearPMSign()
            vcard2.clearPMEncrypt()
            vcard2.clearPMScheme()
            vcard2.clearPMMimeType()

            // update
            for (index, email) in getEmails().enumerated() {
                if email.newEmail.isEmpty || !email.newEmail.isValidEmail() {
                    throw RuntimeError.invalidEmail.toError()
                }
                let group = "Item\(index + 1)"
                let rawEmail = email.newEmail
                if !rawEmail.isEmpty {
                    defaultName = rawEmail
                    if let rawEmailObject = PMNIEmail.createInstance(
                        email.newType.vcardType,
                        email: email.newEmail,
                        group: group
                    ) {
                        newEmails.append(rawEmailObject)
                    }

                    if let keys = email.keys {
                        for key in keys {
                            key.setGroup(group)
                            vcard2.add(key)
                        }
                    }

                    if let sign = email.sign {
                        sign.setGroup(group)
                        vcard2.add(sign)
                    }

                    if let encrypt = email.encrypt {
                        encrypt.setGroup(group)
                        vcard2.add(encrypt)
                    }

                    if let scheme = email.scheme {
                        scheme.setGroup(group)
                        vcard2.add(scheme)
                    }
                    if let mime = email.mimeType {
                        mime.setGroup(group)
                        vcard2.add(mime)
                    }
                }
            }

            // replace emails
            vcard2.setEmails(newEmails)

            if let rawFormattedNameObject = PMNIFormattedName.createInstance(
                profile.newDisplayName.isEmpty ? defaultName : profile.newDisplayName
            ) {
                vcard2.setFormattedName(rawFormattedNameObject)
            }

            // get uid first if null create a new one
            uid = vcard2.getUid()
            if uid == nil || uid?.getValue().isEmpty == true {
                let newuid = "protonmail-ios-" + UUID().uuidString
                let uuid = PMNIUid.createInstance(newuid)
                vcard2.setUid(uuid)
                uid = uuid
            }

            // add others later
            let vcard2Str = PMNIEzvcard.write(vcard2)

            let vCardType2Signature: ArmoredSignature
            do {
                vCardType2Signature = try Sign.signDetached(signingKey: signingKey, plainText: vcard2Str)
            } catch {
                throw error as NSError
            }

            // card 2 object
            let card2 = CardData(type: .SignedOnly,
                                 data: vcard2Str,
                                 signature: vCardType2Signature.value)

            cards.append(card2)
        }

        // start type 3 vcard
        var isCard3Set = false
        if origvCard3 == nil {
            origvCard3 = PMNIVCard.createInstance()
        }

        if let vcard3 = origvCard3 {
            var newCells: [PMNITelephone] = []
            for cell in cells where !cell.isEmpty() {
                if let rawCellPhoneObject = PMNITelephone.createInstance(
                    cell.newType.vcardType,
                    number: cell.newPhone
                ) {
                    newCells.append(rawCellPhoneObject)
                    isCard3Set = true
                }
            }
            // replace all cells
            if !newCells.isEmpty {
                vcard3.setTelephones(newCells)
            } else {
                vcard3.clearTelephones()
            }

            var newAddresses: [PMNIAddress] = []
            for address in addresses where !address.isEmpty() {
                if let rawAddressObject = PMNIAddress.createInstance(
                    address.newType.vcardType,
                    street: address.newStreet,
                    extendstreet: address.newStreetTwo,
                    locality: address.newLocality,
                    region: address.newRegion,
                    zip: address.newPostal,
                    country: address.newCountry,
                    pobox: ""
                ) {
                    newAddresses.append(rawAddressObject)
                    isCard3Set = true
                }
            }
            // replace all addresses
            if !newAddresses.isEmpty {
                vcard3.setAddresses(newAddresses)
            } else {
                vcard3.clearAddresses()
            }

            vcard3.clearOrganizations()
            vcard3.clearNickname()
            vcard3.clearTitle()
            vcard3.clearBirthdays()
            vcard3.clearGender()

            let rawOrganizations = organizations.compactMap { PMNIOrganization.createInstance("", value: $0.newValue) }
            if !rawOrganizations.isEmpty {
                vcard3.setOrganizations(rawOrganizations)
                isCard3Set = true
            }

            let rawNickNames = nickNames.compactMap { PMNINickname.createInstance("", value: $0.newValue) }
            if !rawNickNames.isEmpty {
                rawNickNames.forEach { vcard3.add($0) }
                isCard3Set = true
            }

            let rawTitles = contactTitles.compactMap { PMNITitle.createInstance("", value: $0.newValue) }
            if !rawTitles.isEmpty {
                rawTitles.forEach { vcard3.add($0) }
                isCard3Set = true
            }

            if let birthday = birthday, let rawBirthday = PMNIBirthday.createInstance("", date: birthday.newValue) {
                vcard3.setBirthdays([rawBirthday])
                isCard3Set = true
            }

            if let gender = gender, let rawGender = PMNIGender.createInstance(gender.newValue, text: "") {
                vcard3.setGender(rawGender)
                isCard3Set = true
            }

            if let anniversary = anniversary,
               let rawAnniversary = PMNIAnniversary.createInstance("", date: anniversary.newValue) {
                vcard3.add(rawAnniversary)
                isCard3Set = true
            } else {
                vcard3.clearAnniversaries()
            }

            var newUrls: [PMNIUrl] = []
            for url in urls where !url.isEmpty() {
                if let rawUrlObject = PMNIUrl.createInstance(url.newType.vcardType, value: url.newUrl) {
                    newUrls.append(rawUrlObject)
                    isCard3Set = true
                }
            }
            // replace all urls
            if !newUrls.isEmpty {
                vcard3.setUrls(newUrls)
            } else {
                vcard3.clearUrls()
            }

            if !notes.isEmpty {
                let isNoteExist = notes.contains(where: { !$0.newNote.isEmpty })
                if isNoteExist {
                    notes
                        .filter { !$0.newNote.isEmpty }
                        .forEach { note in
                            if let rawNote = PMNINote.createInstance("", note: note.newNote) {
                                vcard3.add(rawNote)
                                isCard3Set = true
                            }
                        }
                } else {
                    vcard3.clearNote()
                    isCard3Set = true
                }
            }

            for field in fields {
                let rawFieldObject = PMNIPMCustom.createInstance(field.newType.vcardType, value: field.newField)
                vcard3.add(rawFieldObject)
                isCard3Set = true
            }

            // profile image
            vcard3.clearPhotos()
            if let profilePicture = profilePicture,
               let compressedImage = UIImage.resize(image: profilePicture,
                                                    targetSize: CGSize(width: 60, height: 60)),
               let jpegData = compressedImage.jpegData(compressionQuality: 0.5) {
                let image = PMNIPhoto.createInstance(jpegData,
                                                     type: "JPEG",
                                                     isBinary: true)
                vcard3.setPhoto(image)
                isCard3Set = true
            }

            if let structuredName = self.structuredName, !structuredName.isEmpty() {
                let rawStructuredName = PMNIStructuredName.createInstance()
                rawStructuredName?.setGiven(structuredName.firstName)
                rawStructuredName?.setFamily(structuredName.lastName)
                vcard3.setStructuredName(rawStructuredName)
                isCard3Set = true
            }

            let vcard3Str = PMNIEzvcard.write(vcard3)

            let encryptedValueOfvCardType3, vCardType3Signature: String
            do {
                encryptedValueOfvCardType3 = try vcard3Str.encryptNonOptional(
                    withPubKey: userkey.publicKey,
                    privateKey: "",
                    passphrase: ""
                )
                vCardType3Signature = try Sign.signDetached(signingKey: signingKey, plainText: vcard3Str).value
            } catch {
                throw error as NSError
            }

            // card 3 object
            let card3 = CardData(
                type: .SignAndEncrypt,
                data: encryptedValueOfvCardType3,
                signature: vCardType3Signature
            )
            if isCard3Set {
                cards.append(card3)
            }
        }
        return cards
    }

    func delete(complete: @escaping ContactEditSaveComplete) {
        if isNew() {
            complete(nil)
        } else {
            guard let objectID = contactEntity?.objectID.rawValue else {
                let error = NSError(
                    domain: "",
                    code: -1,
                    localizedDescription: LocalString._error_no_object
                )
                complete(error)
                return
            }
            self.dependencies.contactService.queueDelete(objectID: objectID) { error in
                DispatchQueue.main.async {
                    if let err = error {
                        complete(err)
                    } else {
                        complete(nil)
                    }
                }
            }
        }
    }

    func getAllContactGroupCounts() -> [(ID: String, name: String, color: String, count: Int)] {
        let result = contactGroupData
            .map { (ID: $0.key, name: $0.value.name, color: $0.value.color, count: $0.value.count) }
            .sorted(by: { $0.name < $1.name })
        return result
    }

    func getItemsForAddingNewField() -> [InformationType] {
        var result: [InformationType] = defaultSectionsInAddNewMenu
        if gender != nil {
            result.removeAll(where: { $0 == .gender })
        }
        if anniversary != nil {
            result.removeAll(where: { $0 == .anniversary })
        }
        return result
    }

    // swiftlint:disable:next function_body_length
    func addNewItem(of type: InformationType) -> (IndexPath?, Bool) {
        guard let indexOfAddNewField = sections.firstIndex(of: .addNewField) else {
            return (nil, false)
        }
        var section = 0
        var row = 0
        var shouldInsertSection = false
        switch type {
        case .organization:
            if !sections.contains(.organization) {
                sections.insert(.organization, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            organizations.append(.init(type: .organization, value: "", isNew: true))
            section = sections.firstIndex(of: .organization) ?? 0
            row = organizations.count - 1
        case .nickname:
            if !sections.contains(.nickName) {
                sections.insert(.nickName, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            nickNames.append(.init(type: .nickname, value: "", isNew: true))
            section = sections.firstIndex(of: .nickName) ?? 0
            row = nickNames.count - 1
        case .title:
            if !sections.contains(.title) {
                sections.insert(.title, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            contactTitles.append(.init(type: .title, value: "", isNew: true))
            section = sections.firstIndex(of: .title) ?? 0
            row = contactTitles.count - 1
        case .birthday:
            break
        case .gender:
            if !sections.contains(.gender) {
                sections.insert(.gender, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            gender = .init(type: .gender, value: "", isNew: true)
            section = sections.firstIndex(of: .gender) ?? 0
            row = 0
        case .anniversary:
            if !sections.contains(.anniversary) {
                sections.insert(.anniversary, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            anniversary = .init(type: .anniversary, value: "", isNew: true)
            section = sections.firstIndex(of: .anniversary) ?? 0
            row = 0
        case .url:
            if !sections.contains(.url) {
                sections.insert(.url, at: indexOfAddNewField)
                shouldInsertSection = true
            }
            _ = newUrl()
            section = sections.firstIndex(of: .url) ?? 0
            row = urls.count - 1
        }
        return (.init(row: row, section: section), shouldInsertSection)
    }

    func pick(newType supported: [ContactFieldType], pickedTypes: [ContactEditTypeInterface]) -> ContactFieldType {
        // TODO: need to check the size
        var newType = supported[0] // get default
        for type in supported {
            var found = false
            for pickedType in pickedTypes where pickedType.getCurrentType().rawString == type.rawString {
                found = true
                break
            }

            if !found {
                newType = type
                break
            }
        }
        return newType
    }

    // swiftlint:disable:next cyclomatic_complexity
    func needsUpdate() -> Bool {
        let profile = self.getProfile()
        if profile.needsUpdate() {
            return true
        }
        for email in getEmails() where email.needsUpdate() {
            return true
        }

        // encrypted part
        for cell in getCells() where cell.needsUpdate() {
            return true
        }
        for address in getAddresses() where address.needsUpdate() {
            return true
        }
        for organization in organizations where organization.needsUpdate() {
            return true
        }
        for nickName in nickNames where nickName.needsUpdate() {
            return true
        }
        for contactTitle in contactTitles where contactTitle.needsUpdate() {
            return true
        }
        if gender?.needsUpdate() == true {
            return true
        }
        if birthday?.needsUpdate() == true {
            return true
        }
        for url in getUrls() where url.needsUpdate() {
            return true
        }

        let notes = getNotes()
        for note in notes where note.needsUpdate() {
            return true
        }

        for field in getFields() where field.needsUpdate() {
            return true
        }

        if profilePictureNeedsUpdate() {
            return true
        }

        if structuredName?.needsUpdate() == true {
            return true
        }
        if anniversary?.needsUpdate() == true {
            return true
        }

        return false
    }
}

extension ContactEditViewModel {
    private func prepareContactGroupData() {
        let groups = dependencies.user.labelService.getAllLabels(of: .contactGroup)

        for group in groups {
            contactGroupData[group.labelID.rawValue] = (
                name: group.name,
                color: group.color,
                count: group.emailRelations.count
            )
        }
    }

    private func prepareContactData() {
        guard let contact = contactEntity else {
            return
        }

        profile = ContactEditProfile(o_displayname: contact.name)
        let cards = contact.cardDatas
        let contactID: ContactID = contact.contactID
        for card in cards.sorted(by: { $0.type.rawValue < $1.type.rawValue }) {
            switch card.type {
            case .PlainText:
                self.contactParser
                    .parsePlainTextContact(data: card.data,
                                           contextProvider: dependencies.contextProvider,
                                           contactID: contactID)
            case .EncryptedOnly:
                try? self.contactParser
                    .parseEncryptedOnlyContact(card: card,
                                               passphrase: dependencies.user.mailboxPassword,
                                               userKeys: dependencies.user.userInfo.userKeys.toArmoredPrivateKeys)
            case .SignedOnly:
                self.contactParser
                    .parsePlainTextContact(data: card.data,
                                           contextProvider: dependencies.contextProvider,
                                           contactID: contactID)
            case .SignAndEncrypt:
                let userInfo = dependencies.user.userInfo
                try? self.contactParser
                    .parseSignAndEncryptContact(
                        card: card,
                        passphrase: dependencies.user.mailboxPassword,
                        firstUserKey: userInfo.firstUserKey().map { ArmoredKey(value: $0.privateKey) },
                        userKeys: userInfo.userKeys.toArmoredPrivateKeys
                    )
            }
        }
    }

}

extension ContactEditViewModel: ContactEditViewModelContactGroupDelegate {
    func updateContactCounts(increase: Bool, contactGroups: Set<String>) {
        for group in contactGroups {
            if increase {
                if var value = contactGroupData[group] {
                    value.count += 1
                    contactGroupData.updateValue(value, forKey: group)
                } else {
                    // TODO: handle error
                }
            } else {
                if var value = contactGroupData[group] {
                    value.count -= 1
                    contactGroupData.updateValue(value, forKey: group)
                } else {
                    // TODO: handle error
                }
            }
        }
    }
}

extension ContactEditViewModel: ContactParserResultDelegate {
    func append(structuredName: ContactEditStructuredName) {
        self.structuredName = structuredName
    }

    func append(emails: [ContactEditEmail]) {
        self.emails.append(contentsOf: emails)
    }

    func append(addresses: [ContactEditAddress]) {
        self.addresses.append(contentsOf: addresses)
    }

    func append(telephones: [ContactEditPhone]) {
        self.cells.append(contentsOf: telephones)
    }

    func append(informations: [ContactEditInformation]) {
        for info in informations {
            switch info.infoType {
            case .birthday:
                birthday = info
            case .title:
                contactTitles.append(info)
            case .organization:
                organizations.append(info)
            case .gender:
                gender = info
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

    func update(verifyType3: Bool) {}

    func update(decryptionError: Bool) {}

    func update(profilePicture: UIImage?) {
        self.profilePicture = profilePicture
    }
}

extension ContactEditViewModel {
    struct Dependencies {
        let user: UserManager
        let contextProvider: CoreDataContextProviderProtocol
        let contactService: ContactDataServiceProtocol
    }
}

enum RuntimeError: Int, Error, CustomErrorVar {
    case invalidEmail = 0x0001

    var code: Int {
        return self.rawValue
    }

    var desc: String {
        return reason
    }

    var reason: String {
        switch self {
        case .invalidEmail:
            return LocalString._please_input_a_valid_email_address
        }
    }
}
