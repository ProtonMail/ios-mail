//
//  ContactDetailsViewModelImpl.swift
//  ProtonMail - Created on 5/2/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PromiseKit
import AwaitKit
import Crypto


class ContactDetailsViewModelImpl : ContactDetailsViewModel {
    
    var contact : Contact!
    var origEmails : [ContactEditEmail] = []
    var origAddresses : [ContactEditAddress] = []
    var origTelephons : [ContactEditPhone] = []
    var origInformations : [ContactEditInformation] = []
    var origFields : [ContactEditField] = []
    var origNotes: [ContactEditNote] = []
    var origUrls: [ContactEditUrl] = []
    var profilePicture: UIImage? = nil
    
    var verifyType2 : Bool = true
    var verifyType3 : Bool = true
    
    var decryptError : Bool = false
    
    var contactService: ContactDataService
    
    //default
    var typeSection: [ContactEditSectionType] = [.email_header,
                                                 .emails,
                                                 .encrypted_header,
                                                 .cellphone,
                                                 .home_address,
                                                 .url,
                                                 .information,
                                                 .custom_field,
                                                 .notes]
    init(c : Contact, user: UserManager) {
        self.contactService = user.contactService
        super.init(user: user)
        self.contact = c
        //        if paidUser() {
        typeSection = [.email_header,
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
                       .share]
        //        } else {
        //            typeSection = [.email_header,
        //                           .type2_warning,
        //                           .emails,
        //                           .encrypted_header,
        //                           .upgrade,
        //                           .share]
        //        }
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
    
    @discardableResult
    private func setupEmails() -> Promise<Void> {
        return firstly { () -> Promise<Void> in
            let userInfo = self.user.userInfo
            
            //  origEmails
            let cards = self.contact.getCardData()
            for c in cards.sorted(by: {$0.type.rawValue < $1.type.rawValue}) {
                switch c.type {
                case .PlainText:
                    if let vcard = PMNIEzvcard.parseFirst(c.data) {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let typeRaw = types.count > 0 ? types.first! : ""
                            let type = ContactFieldType.get(raw: typeRaw)
                            
                            let ce = ContactEditEmail(order: order,
                                                      type: type == .empty ? .email : type,
                                                      email:e.getValue(),
                                                      isNew: false,
                                                      keys: nil,
                                                      contactID: self.contact.contactID,
                                                      encrypt: nil,
                                                      sign: nil ,
                                                      scheme: nil,
                                                      mimeType: nil,
                                                      delegate: nil)
                            origEmails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .EncryptedOnly:
                    break
                case .SignedOnly:
                    let userkeys = userInfo.userKeys
                    for key in userkeys {
                        do {
                            let verifyStatus = try Crypto().verifyDetached(signature: c.sign,
                                                                           plainText: c.data,
                                                                           publicKey: key.publicKey,
                                                                           verifyTime: 0)
                            self.verifyType2 = verifyStatus
                            if self.verifyType2 {
                                if !key.private_key.check(passphrase: user.mailboxPassword) {
                                    self.verifyType2 = false
                                }
                                break
                            }
                            
                        } catch {
                            self.verifyType2 = false
                        }
                    }
                    
                    if let vcard = PMNIEzvcard.parseFirst(c.data) {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let typeRaw = types.count > 0 ? types.first! : ""
                            let type = ContactFieldType.get(raw: typeRaw)
                            
                            let ce = ContactEditEmail(order: order,
                                                      type:type == .empty ? .email : type,
                                                      email:e.getValue(),
                                                      isNew: false,
                                                      keys: nil,
                                                      contactID: self.contact.contactID,
                                                      encrypt: nil,
                                                      sign: nil ,
                                                      scheme: nil,
                                                      mimeType: nil,
                                                      delegate: nil)
                            origEmails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .SignAndEncrypt:
                    guard let firstUserkey = userInfo.firstUserKey() else {
                        return Promise.value(())
                    }
                    var pt_contact : String?
                    var signKey : Key?
                    let userkeys = userInfo.userKeys
                    for key in userkeys {
                        do {
                            pt_contact = try c.data.decryptMessageWithSinglKey(key.private_key,
                                                                               passphrase: user.mailboxPassword)
                            signKey = key
                            self.decryptError = false
                            break
                        } catch {
                            self.decryptError = true
                        }
                    }
                    
                    let key = signKey ?? firstUserkey
                    guard let pt_contact_vcard = pt_contact else {
                        break
                    }
                    
                    do {
                        let verifyStatus = try Crypto().verifyDetached(signature: c.sign,
                                                                       plainText: pt_contact_vcard,
                                                                       publicKey: key.publicKey,
                                                                       verifyTime: 0)
                        self.verifyType3 = verifyStatus
                    } catch {
                        self.verifyType3 = false
                    }
                    
                    do {
                        try ObjC.catchException {
                            if let vcard = PMNIEzvcard.parseFirst(pt_contact_vcard) {
                                let types = vcard.getPropertyTypes()
                                for type in types {
                                    switch type {
                                    case "Telephone":
                                        let telephones = vcard.getTelephoneNumbers()
                                        var order : Int = 1
                                        for t in telephones {
                                            let types = t.getTypes()
                                            let typeRaw = types.count > 0 ? types.first! : ""
                                            let type = ContactFieldType.get(raw: typeRaw)
                                            let cp = ContactEditPhone(order: order, type:type == .empty ? .phone : type, phone:t.getText(), isNew: false)
                                            self.origTelephons.append(cp)
                                            order += 1
                                        }
                                    case "Address":
                                        let addresses = vcard.getAddresses()
                                        var order : Int = 1
                                        for a in addresses {
                                            let types = a.getTypes()
                                            let typeRaw = types.count > 0 ? types.first! : ""
                                            let type = ContactFieldType.get(raw: typeRaw)
                                            let pobox = a.getPoBoxes().joined(separator: ",")
                                            let street = a.getStreetAddress()
                                            let extention = a.getExtendedAddress()
                                            let locality = a.getLocality()
                                            let region = a.getRegion()
                                            let postal = a.getPostalCode()
                                            let country = a.getCountry()
                                            
                                            let ca = ContactEditAddress(order: order, type: type == .empty ? .address : type,
                                                                        pobox: pobox, street: street, streetTwo: extention,
                                                                        locality: locality, region: region,
                                                                        postal: postal, country: country, isNew: false)
                                            self.origAddresses.append(ca)
                                            order += 1
                                        }
                                    case "Organization":
                                        let org = vcard.getOrganization()
                                        let info = ContactEditInformation(type: .organization, value:org?.getValue() ?? "", isNew: false)
                                        self.origInformations.append(info)
                                    case "Title":
                                        let title = vcard.getTitle()
                                        let info = ContactEditInformation(type: .title, value:title?.getTitle() ?? "", isNew: false)
                                        self.origInformations.append(info)
                                    case "Nickname":
                                        let nick = vcard.getNickname()
                                        let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "", isNew: false)
                                        self.origInformations.append(info)
                                    case "Birthday":
                                        let births = vcard.getBirthdays()
                                        for b in births {
                                            let info = ContactEditInformation(type: .birthday, value:b.getText(), isNew: false)
                                            self.origInformations.append(info)
                                        }
                                    case "Anniversary":
                                        break
                                    case "Gender":
                                        if let gender = vcard.getGender() {
                                            let info = ContactEditInformation(type: .gender, value: gender.getGender(), isNew: false)
                                            self.origInformations.append(info)
                                        }
                                    case "Url":
                                        let urls = vcard.getUrls()
                                        var order : Int = 1
                                        for url in urls {
                                            let typeRaw = url.getType()
                                            let type = ContactFieldType.get(raw: typeRaw)
                                            let cu = ContactEditUrl(order: order, type:type == .empty ? .url : type, url:url.getValue(), isNew: false)
                                            self.origUrls.append(cu)
                                            order += 1
                                        }
                                    case "Photo":
                                        let photo = vcard.getPhoto()
                                        if let image = photo?.getRawData() {
                                            let data = Data.init(image)
                                            self.profilePicture = UIImage.init(data: data)
                                        }
                                        
                                        break
                                        
                                        //case "Agent":
                                        //case "CalendarRequestUri":
                                        //case "CalendarUri":
                                        //case "Categories":
                                        //case "Classification":
                                        //case "ClientPidMap":
                                        //case "Email": //this in type2
                                        //case "FreeBusyUrl":
                                        //case "FormattedName":
                                        //case "Geo":
                                        //case "Impp":
                                        
                                        //"Key":
                                        //"KindScribe())
                                        //"LabelScribe())
                                        //"LanguageScribe())
                                        //"LogoScribe())
                                        //"MailerScribe())
                                        //"MemberScribe())
                                        //"NicknameScribe())
                                        //"NoteScribe())
                                        //"OrganizationScribe())
                                        //"PhotoScribe())
                                        //"ProductIdScribe())
                                        //"ProfileScribe())
                                        //"RelatedScribe())
                                        //"RevisionScribe())
                                        //"RoleScribe())
                                        //"SortStringScribe())
                                        //"SoundScribe())
                                        //"SourceDisplayTextScribe())
                                        //"SourceScribe())
                                        //"StructuredNameScribe())
                                        //"TelephoneScribe())
                                        //"TimezoneScribe())
                                        //"TitleScribe())
                                        //"UidScribe())
                                        //"UrlScribe())
                                        //"BirthplaceScribe())
                                        //"DeathdateScribe())
                                        //"DeathplaceScribe())
                                        //"ExpertiseScribe())
                                        //"OrgDirectoryScribe())
                                        //"InterestScribe())
                                    //"HobbyScribe())
                                    default:
                                        break
                                    }
                                }
                                
                                let customs = vcard.getCustoms()
                                var order : Int = 1
                                for t in customs {
                                    let typeRaw = t.getType()
                                    let type = ContactFieldType.get(raw: typeRaw)
                                    let cp = ContactEditField(order: order, type: type, field: t.getValue(), isNew: false)
                                    self.origFields.append(cp)
                                    order += 1
                                }
                                
                                if let note = vcard.getNote() {
                                    let n = ContactEditNote(note: note.getNote(), isNew: false)
                                    n.isNew = false
                                    self.origNotes.append(n)
                                }
                                
                            }
                        }
                    } catch let error {
                        return Promise(error: error)
                    }
                    break
                }
            }
            self.contact.needsRebuild = false
            let _ = self.contact.managedObjectContext?.saveUpstreamIfNeeded()
            
            if self.origEmails.count == 0 {
                for (i, item) in self.typeSection.enumerated() {
                    if item == .email_header {
                        self.typeSection.remove(at: i)
                        break
                    }
                }
            }
            
            return Promise.value(())
        }
    }
    
    override func getDetails(loading: () -> Void) -> Promise<Contact> {
        if contact.isDownloaded && contact.needsRebuild == false {
            return firstly {
                self.setupEmails()
            }.then {
                return Promise.value(self.contact)
            }
        }
        loading()
        return Promise { seal in
            //Fixme
            self.contactService.details(contactID: contact.contactID).then { _ in
                self.setupEmails()
            }.done {
                seal.fulfill(self.contact)
            }.catch { (error) in
                seal.reject(error)
            }
        }
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
    
    override func getContact() -> Contact {
        return self.contact
    }
    
    override func export() -> String {
        let cards = self.contact.getCardData()
        var vcard : PMNIVCard? = nil
        let userInfo = self.user.userInfo
        for c in cards {
            if c.type == .SignAndEncrypt {
                var pt_contact : String?
                let userkeys = userInfo.userKeys
                for key in userkeys {
                    do {
                        pt_contact = try c.data.decryptMessageWithSinglKey(key.private_key,
                                                                           passphrase: user.mailboxPassword)
                        break
                    } catch {
                    }
                }
                

                guard let pt_contact_vcard = pt_contact else {
                    break
                }
                vcard = PMNIEzvcard.parseFirst(pt_contact_vcard)
            }
        }

        for c in cards {
            if c.type == .PlainText {
                if let card = PMNIEzvcard.parseFirst(c.data) {
                    let emails = card.getEmails()
                    let fn = card.getFormattedName()
                    if vcard != nil {
                        vcard!.setEmails(emails)
                        vcard!.setFormattedName(fn)
                    } else {
                        vcard = card
                    }
                }
            }
        }

        for c in cards {
            if c.type == .SignedOnly {
                if let card = PMNIEzvcard.parseFirst(c.data) {
                    let emails = card.getEmails()
                    let fn = card.getFormattedName()
                    if vcard != nil {
                        vcard!.setEmails(emails)
                        vcard!.setFormattedName(fn)
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
