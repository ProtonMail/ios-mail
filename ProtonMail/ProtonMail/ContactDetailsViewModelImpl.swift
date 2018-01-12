//
//  ContactDetailsViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


class ContactDetailsViewModelImpl : ContactDetailsViewModel {
    
    var contact : Contact!
    var origEmails : [ContactEditEmail] = []
    var origAddresses : [ContactEditAddress] = []
    var origTelephons : [ContactEditPhone] = []
    var origInformations : [ContactEditInformation] = []
    var origFields : [ContactEditField] = []
    var origNotes: [ContactEditNote] = []
    
    var origUrls: [ContactEditUrl] = []
    
    var verifyType2 : Bool = false
    var verifyType3 : Bool = false

    //default
    var typeSection: [ContactEditSectionType] = [.display_name,
                                                 .emails,
                                                 .encrypted_header,
                                                 .cellphone,
                                                 .home_address,
                                                 .url,
                                                 .information,
                                                 .custom_field,
                                                 .notes]
    init(c : Contact) {
        super.init()
        self.contact = c
        if paidUser() {
            typeSection = [.display_name,
                           .emails,
                           .encrypted_header,
                           .cellphone,
                           .home_address,
                           .url,
                           .information,
                           .custom_field,
                           .notes,
                           .share]
        } else {
            typeSection = [.display_name,
                           .emails,
                           .encrypted_header,
                           .upgrade,
                           .share]
        }
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
    
    override func hasEncryptedContacts() -> Bool {
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
    
    private func setupEmails() {
        //  origEmails
        let cards = self.contact.getCardData()
        for c in cards {
            switch c.type {
            case .PlainText:
                if let vcard = PMNIEzvcard.parseFirst(c.data) {
                    let emails = vcard.getEmails()
                    var order : Int = 1
                    for e in emails {
                        let types = e.getTypes()
                        let typeRaw = types.count > 0 ? types.first! : ""
                        let type = ContactFieldType.get(raw: typeRaw)
                        let ce = ContactEditEmail(order: order, type: type == .empty ? .email : type, email:e.getValue(), isNew: false)
                        origEmails.append(ce)
                        order += 1
                    }
                }
                break
            case .EncryptedOnly: break
            case .SignedOnly:
                guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                    return; //with error
                }
                self.verifyType2 = sharedOpenPGP.signVerify(detached: c.sign, publicKey: userkey.public_key, plainText: c.data)
                if let vcard = PMNIEzvcard.parseFirst(c.data) {
                    let emails = vcard.getEmails()
                    var order : Int = 1
                    for e in emails {
                        let types = e.getTypes()
                        let typeRaw = types.count > 0 ? types.first! : ""
                        let type = ContactFieldType.get(raw: typeRaw)
                        let ce = ContactEditEmail(order: order, type:type == .empty ? .email : type, email:e.getValue(), isNew: false)
                        origEmails.append(ce)
                        order += 1
                    }
                }
                break
            case .SignAndEncrypt:
                guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                    return; //with error
                }
                let pt_contact = sharedOpenPGP.decryptMessage(c.data, passphras: sharedUserDataService.mailboxPassword!)
                self.verifyType3 = sharedOpenPGP.signDetachedVerify(userkey.public_key, signature: c.sign, plainText: pt_contact)
                if let vcard = PMNIEzvcard.parseFirst(pt_contact) {
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
                                origTelephons.append(cp)
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
                                //let extention =
                                let locality = a.getLocality()
                                let region = a.getRegion()
                                let postal = a.getPostalCode()
                                let country = a.getCountry()
                                
                                let ca = ContactEditAddress(order: order, type: type == .empty ? .address : type , pobox: pobox, street: street,
                                                            locality: locality, region: region,
                                                            postal: postal, country: country, isNew: false)
                                origAddresses.append(ca)
                                order += 1
                            }
                        case "Organization":
                            let org = vcard.getOrganization()
                            let info = ContactEditInformation(type: .organization, value:org?.getValue() ?? "")
                            origInformations.append(info)
                        case "Title":
                            let title = vcard.getTitle()
                            let info = ContactEditInformation(type: .title, value:title?.getTitle() ?? "")
                            origInformations.append(info)
                        case "Nickname":
                            let nick = vcard.getNickname()
                            let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "")
                            origInformations.append(info)
                        case "Birthday":
//                            let nick = vcard.ge
//                            let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "")
//                            origInformations.append(info)
                            break
                        case "Anniversary":
                            break
                        case "Gender":
                            let urls = vcard.getUrls()
                            var order : Int = 1
                            for url in urls {
                                let typeRaw = url.getType()
                                //let typeRaw = types.count > 0 ? types.first! : ""
                                let type = ContactFieldType.get(raw: typeRaw)
                                let cu = ContactEditUrl(order: order, type:type == .empty ? .url : type, url:url.getValue(), isNew: false)
                                origUrls.append(cu)
                                order += 1
                            }
                        case "Url":
                            break
                            
                            
                            //case "Agent":
                            //case "Birthday":
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
                            
                            //[0] = "Telephone"
                            //[1] = "Organization"
                            //[2] = "Address"
                            //[3] = "Nickname"
                            //[4] = "RawProperty"
                            //[5] = "Title"
                            //[6] = "Birthday"
                            //[7] = "Url"
                            //[8] = "Note"
                            
                            //
                            //"Key":
                            //"KindScribe());
                            //"LabelScribe());
                            //"LanguageScribe());
                            //"LogoScribe());
                            //"MailerScribe());
                            //"MemberScribe());
                            //"NicknameScribe());
                            //"NoteScribe());
                            //"OrganizationScribe());
                            //"PhotoScribe());
                            //"ProductIdScribe());
                            //"ProfileScribe());
                            //"RelatedScribe());
                            //"RevisionScribe());
                            //"RoleScribe());
                            //"SortStringScribe());
                            //"SoundScribe());
                            //"SourceDisplayTextScribe());
                            //"SourceScribe());
                            //"StructuredNameScribe());
                            //"TelephoneScribe());
                            //"TimezoneScribe());
                            //"TitleScribe());
                            //"UidScribe());
                            //"UrlScribe());
                            //"BirthplaceScribe());
                            //"DeathdateScribe());
                            //"DeathplaceScribe());
                            //"ExpertiseScribe());
                            //"OrgDirectoryScribe());
                            //"InterestScribe());
                        //"HobbyScribe());
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
                        origFields.append(cp)
                        order += 1
                    }
                    
                    if let note = vcard.getNote() {
                        let n = ContactEditNote(note: note.getNote(), isNew: false)
                        n.isNew = false
                        origNotes.append(n)
                        
                    }
                }
                break
            }
        }
    }
    
    override func getDetails(loading: () -> Void, complete: @escaping (Contact?, NSError?) -> Void) {
        if contact.isDownloaded {
            self.setupEmails()
            return complete(contact, nil)
        }
        loading()
        sharedContactDataService.details(contactID: contact.contactID, completion: { (contact : Contact?, error : NSError?) in
            self.setupEmails()
            complete(contact, nil)
        })
    }
    
    override func getProfile() -> ContactEditProfile {
        return ContactEditProfile(n_displayname: contact.name, isNew: false)
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
        
        for c in cards {
            if c.type == .SignAndEncrypt {
//                guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
//                    return "";
//                }
                let pt_contact = sharedOpenPGP.decryptMessage(c.data, passphras: sharedUserDataService.mailboxPassword!)
                vcard = PMNIEzvcard.parseFirst(pt_contact)
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
