//
//  ContactAddViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



class ContactAddViewModelImpl : ContactEditViewModel {
    var sections: [ContactEditSectionType] = [.display_name,
                                              .emails,
                                              .encrypted_header,
                                              .cellphone,
                                              .home_address,
                                              .url,
                                              .information,
                                              .notes]
    
    var contact : Contact? //optional if nil add new contact
    var emails : [ContactEditEmail] = []
    var cells : [ContactEditPhone] = []
    var urls : [ContactEditUrl] = []
    var addresses : [ContactEditAddress] = []
    var informations: [ContactEditInformation] = []
    var fields : [ContactEditField] = []
    var notes : ContactEditNote = ContactEditNote(note: "", isNew: true)
    var profile : ContactEditProfile = ContactEditProfile(n_displayname: "")
    
    override init() {
        super.init()
        self.contact = nil
        
        if !paidUser() {
            sections = [.display_name,
                        .emails,
                        .encrypted_header,
                        .upgrade]
        }
    }
    
    override func getSections() -> [ContactEditSectionType] {
        return self.sections
    }
    override func sectionCount() -> Int {
        return sections.count
    }
    //
    override func isNew() -> Bool {
        return true
    }
    
    override func getEmails() -> [ContactEditEmail] {
        return emails
    }
    
    override func getCells() -> [ContactEditPhone] {
        return cells
    }
    
    override func getAddresses() -> [ContactEditAddress] {
        return addresses
    }
    
    override func getInformations() -> [ContactEditInformation] {
        return informations
    }
    
    override func getFields() -> [ContactEditField] {
        return fields
    }
    
    override func getNotes() -> ContactEditNote {
        return notes
    }
    
    override func getProfile() -> ContactEditProfile {
        return profile
    }
    
    override func getUrls() -> [ContactEditUrl] {
        return urls
    }

    //new functions
    override func newUrl() -> ContactEditUrl {
        let type = pick(newType: ContactFieldType.urlTypes, pickedTypes: urls)
        let url = ContactEditUrl(order: urls.count, type: type, url:"", isNew: true)
        urls.append(url)
        return url
    }
    override func deleteUrl(at index: Int) {
        if urls.count > index {
            urls.remove(at: index)
        }
    }
    override func newEmail() -> ContactEditEmail {
        let type = pick(newType: ContactFieldType.emailTypes, pickedTypes: emails)
        let email = ContactEditEmail(order: emails.count, type: type, email:"", isNew: true)
        emails.append(email)
        return email
    }
    
    override func deleteEmail(at index: Int) {
        if emails.count > index {
            emails.remove(at: index)
        }
    }
    
    override func newPhone() -> ContactEditPhone {
        let type = pick(newType: ContactFieldType.phoneTypes, pickedTypes: cells)
        let cell = ContactEditPhone(order: emails.count, type: type, phone:"", isNew: true)
        cells.append(cell)
        return cell
    }
    
    override func deletePhone(at index: Int) {
        if cells.count > index {
            cells.remove(at: index)
        }
    }
    
    override func newAddress() -> ContactEditAddress {
        let type = pick(newType: ContactFieldType.addrTypes, pickedTypes: addresses)
        let addr = ContactEditAddress(order: emails.count, type: type)
        addresses.append(addr)
        return addr
    }
    
    override func deleteAddress(at index: Int) {
        if addresses.count > index {
            addresses.remove(at: index)
        }
    }
    
    override func newInformation(type: InformationType) -> ContactEditInformation {
        let info = ContactEditInformation(type: type, value:"", isNew: true)
        informations.append(info)
        return info
    }
    
    override func deleteInformation(at index: Int) {
        if informations.count > index {
            informations.remove(at: index)
        }
    }
    
    override func newField() -> ContactEditField {
        let type = pick(newType: ContactFieldType.fieldTypes, pickedTypes: fields)
        let field = ContactEditField(order: emails.count, type: type, field:"", isNew: true)
        fields.append(field)
        return field
    }
    
    override func deleteField(at index: Int) {
        if fields.count > index {
            fields.remove(at: index)
        }
    }
    
    override func done(complete : @escaping ContactEditSaveComplete) {
        //add
        var a_emails: [ContactEmail] = []
        for e in getEmails() {
            a_emails.append(e.toContactEmail())
        }
        guard let vcard2 = PMNIVCard.createInstance() else {
            return; //with error
        }
        
        var defaultName = NSLocalizedString("Unknown", comment: "title, default display name")
        var i : Int = 1;
        for email in a_emails {
            let group = "Item\(i)"
            let em = email.email
            if !em.isEmpty {
                defaultName = em
                let m = PMNIEmail.createInstance(email.type, email: email.email, group: group)
                vcard2.add(m)
                i += 1
            }
        }
        
        if let fn = PMNIFormattedName.createInstance(profile.newDisplayName.isEmpty ? defaultName : profile.newDisplayName) {
            vcard2.setFormattedName(fn)
        }
        
        //generate UID
        let newuid = "protonmail-ios-" + UUID().uuidString
        let uuid = PMNIUid.createInstance(newuid)
        vcard2.setUid(uuid)
        
        // add others later
        let vcard2Str = PMNIEzvcard.write(vcard2)
        guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
            return; //with error
        }
        PMLog.D(vcard2Str);
        let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key,
                                                       plainText: vcard2Str,
                                                       passphras: sharedUserDataService.mailboxPassword!)
        
        //card 2 object
        let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
        
        var isCard3Set : Bool = false
        //
        guard let vcard3 = PMNIVCard.createInstance() else {
            return; //with error
        }
        for cell in cells {
            let value = cell.newPhone
            if !value.isEmpty {
                let c = PMNITelephone.createInstance(cell.newType.vcardType, number: value)
                vcard3.add(c)
                isCard3Set = true
            }
        }
        
        for addr in addresses {
            let a = PMNIAddress.createInstance(addr.newType.vcardType,
                                               street: addr.newStreet,
                                               extendstreet: addr.newStreetTwo,
                                               locality: addr.newLocality,
                                               region: addr.newRegion,
                                               zip: addr.newPostal,
                                               country: addr.newCountry,
                                               pobox: "")
            vcard3.add(a)
            isCard3Set = true
        }
        
        for info in informations {
            switch info.infoType {
            case .organization:
                let value = info.newValue
                if !value.isEmpty {
                    let org = PMNIOrganization.createInstance("", value: value)
                    vcard3.add(org)
                    isCard3Set = true
                }
            case .nickname:
                let value = info.newValue
                if !value.isEmpty {
                    let nn = PMNINickname.createInstance("", value: value)
                    vcard3.setNickname(nn)
                    isCard3Set = true
                }
            case .title:
                let value = info.newValue
                if !value.isEmpty {
                    let t = PMNITitle.createInstance("", value: value)
                    vcard3.setTitle(t)
                    isCard3Set = true
                }
            case .birthday:
                let value = info.newValue
                if !value.isEmpty {
                    let b = PMNIBirthday.createInstance("", date: value)!
                    vcard3.setBirthdays([b])
                    isCard3Set = true
                }
            case .anniversary:
                break
            case .gender:
                let value = info.newValue
                if !value.isEmpty {
                    let g = PMNIGender.createInstance(value, text: "")!
                    vcard3.setGender(g)
                    isCard3Set = true
                }
            }
        }
        
        for url in urls {
            let value = url.newUrl
            if !value.isEmpty {
                let f = PMNIUrl.createInstance(url.newType.vcardType, value: value)
                vcard3.add(f)
                isCard3Set = true
            }
        }
        
        if notes.newNote != "" {
            let n = PMNINote.createInstance("", note: notes.newNote)
            vcard3.setNote(n)
            isCard3Set = true
        }
        
        for field in fields{
            let f = PMNIPMCustom.createInstance(field.newType.vcardType, value: field.newField)
            vcard3.add(f)
            isCard3Set = true
        }
        
        vcard3.setUid(uuid)
        
        let vcard3Str = PMNIEzvcard.write(vcard3)
        PMLog.D(vcard3Str);
        let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str, privateKey: "", passphras: "")
        PMLog.D(encrypted_vcard3);
        let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                       plainText: vcard3Str,
                                                       passphras: sharedUserDataService.mailboxPassword!)
        //card 3 object
        let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
        
        var cards : [CardData] = [card2]
        if isCard3Set {
            cards.append(card3)
        }
        
        sharedContactDataService.add(cards: [cards],
                                     completion:  { (contacts : [Contact]?, error : NSError?) in
                                        if error == nil {
                                            complete(nil)
                                        } else {
                                            complete(error)
                                        }
        })
    }
    
    override func delete(complete: @escaping ContactEditViewModel.ContactEditSaveComplete) {
        complete(nil)
    }
}
