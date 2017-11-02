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
                                              .information,
                                              .custom_field,
                                              .notes]
    
    var contact : Contact? //optional if nil add new contact
    var emails : [ContactEditEmail] = []
    var cells : [ContactEditPhone] = []
    var addresses : [ContactEditAddress] = []
    var informations: [ContactEditInformation] = []
    var fields : [ContactEditField] = []
    var notes : ContactEditNote = ContactEditNote(n_note: "")
    var profile : ContactEditProfile = ContactEditProfile(n_displayname: "")
    
    override init() {
        super.init()
        self.contact = nil
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
    
    override func getOrigEmails() -> [ContactEditEmail] {
        return emails
    }
    
    override func getOrigCells() -> [ContactEditPhone] {
        return cells
    }
    
    override func getOrigAddresses() -> [ContactEditAddress] {
        return addresses
    }
    
    override func getOrigInformations() -> [ContactEditInformation] {
        return informations
    }
    
    override func getOrigFields() -> [ContactEditField] {
        return fields
    }
    
    override func getOrigNotes() -> ContactEditNote {
        return notes
    }
    
    override func getProfile() -> ContactEditProfile {
        return profile
    }
    
    func getNewType(types: [String], typeInterfaces: [ContactEditTypeInterface]) -> String {
        var newType = types[0]
        for type in types {
            var found = false
            for e in typeInterfaces {
                if e.getCurrentType() == type {
                    found = true
                    break
                }
            }
            
            if !found {
                newType = type
                break
            }
        }
        return newType
    }
    
    //new functions
    override func newEmail() -> ContactEditEmail {
        let newType = getNewType(types: ContactEmailType.allValues, typeInterfaces: emails)
        let email = ContactEditEmail(n_order: emails.count, n_type: newType, n_email:"")
        emails.append(email)
        return email
    }
    
    override func newPhone() -> ContactEditPhone {
        let newType = getNewType(types: ContactPhoneType.allValues, typeInterfaces: cells)
        let cell = ContactEditPhone(n_order: emails.count, n_type: newType, n_phone:"")
        cells.append(cell)
        return cell
    }
    
    override func newAddress() -> ContactEditAddress {
        let newType = getNewType(types: ContactAddressType.allValues, typeInterfaces: addresses)
        let addr = ContactEditAddress(n_order: emails.count, n_type: newType, n_street:"")
        addresses.append(addr)
        return addr
    }
    
    override func newInformation(type: InformationType) -> ContactEditInformation {
        let info = ContactEditInformation(type: type, value:"")
        informations.append(info)
        return info
    }
    
    override func newField() -> ContactEditField {
        let newType = getNewType(types: ContactFieldType.allValues, typeInterfaces: fields)
        let field = ContactEditField(n_order: emails.count, n_type: newType, n_field:"")
        fields.append(field)
        return field
    }
    
    override func done(complete : @escaping ContactEditSaveComplete) {
        //add
        var a_emails: [ContactEmail] = []
        for e in getOrigEmails() {
            a_emails.append(e.toContactEmail())
        }
        //            let a_data: ContactDate
        guard let vcard2 = PMNIVCard.createInstance() else {
            return; //with error
        }
        
        if let fn = PMNIFormattedName.createInstance(profile.newDisplayName) {
            vcard2.setFormattedName(fn)
        }
        
        var i : Int = 1;
        for email in a_emails {
            let group = "Item\(i)"
            let m = PMNIEmail.createInstance(email.type, email: email.email, group: group)
            vcard2.add(m)
            i += 1
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
        let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key, plainText: vcard2Str, passphras: sharedUserDataService.mailboxPassword!)
        
        //card 2 object
        let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
        
        var isCard3Set : Bool = false
        //
        guard let vcard3 = PMNIVCard.createInstance() else {
            return; //with error
        }
        for cell in cells {
            let c = PMNITelephone.createInstance(cell.newType, number: cell.newPhone)
            vcard3.add(c)
            isCard3Set = true
        }
        
        for addr in addresses {
            let a = PMNIAddress.createInstance(addr.newType,
                                               street: addr.newStreet,
                                               locality: "",
                                               region: "",
                                               zip: "",
                                               country: "",
                                               pobox: "")
            vcard3.add(a)
            isCard3Set = true
        }
        
        for info in informations {
            switch info.infoType {
            case .organization:
                let org = PMNIOrganization.createInstance("", value: info.newValue)
                vcard3.add(org)
                isCard3Set = true
            case .nickname:
                let nn = PMNINickname.createInstance("", value: info.newValue)
                vcard3.add(nn)
                isCard3Set = true
            case .title:
                let t = PMNITitle.createInstance("", value: info.newValue)
                vcard3.add(t)
                isCard3Set = true
            case .birthday:
                break
            case .anniversary:
                break
            }
        }
        
        
        if notes.newNote != "" {
            let n = PMNINote.createInstance("", note: notes.newNote)
            vcard3.add(n)
            isCard3Set = true
        }
        
        
        for field in fields{
            let f = PMNIPMCustom.createInstance(field.newType, value: field.newField)
            vcard3.add(f)
            isCard3Set = true
        }
        //            override func getProfile() -> ContactEditProfile {
        //                return profile
        //            }
        
        vcard3.setUid(uuid)
        
        let vcard3Str = PMNIEzvcard.write(vcard3)
        PMLog.D(vcard3Str);
        let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str)
        PMLog.D(encrypted_vcard3);
        let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                       plainText: vcard3Str,
                                                       passphras: sharedUserDataService.mailboxPassword!)
        //card 2 object
        let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
        
        var cards : [CardData] = [card2]
        if isCard3Set {
            cards.append(card3)
        }
        
        sharedContactDataService.add(name: profile.newDisplayName,
                                     emails: a_emails,
                                     cards: cards,
                                     completion:  { (contact : Contact?, error : NSError?) in
                                        if error == nil {
                                            complete(nil)
                                        } else {
                                            complete(error)
                                        }
        })
        
        
        //            var contact : Contact? //optional if nil add new contact
        //            var emails : [ContactEditEmail] = []
        //
        //            //those should be in the
        //            var cells : [ContactEditPhone] = []
        //            var addresses : [ContactEditAddress] = []
        //            var orgs : [ContactEditOrg] = []
        //            var fields : [ContactEditField] = []
        //            var notes : ContactEditNote = ContactEditNote(n_note: "")
        //            var profile : ContactEditProfile = ContactEditProfile(n_displayname: "")
    }
    
    override func delete(complete: @escaping ContactEditViewModel.ContactEditSaveComplete) {
        complete(nil)
    }
}
