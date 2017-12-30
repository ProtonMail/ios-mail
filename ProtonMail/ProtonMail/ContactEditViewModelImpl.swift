//
//  ContactEditViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/3/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



class ContactEditViewModelImpl : ContactEditViewModel {
    var sections : [ContactEditSectionType] = [.display_name,
                                               .emails,
                                               .encrypted_header,
                                               .cellphone,
                                               .home_address,
                                               .information,
//                                               .custom_field,
                                               .notes,
                                               .delete]

    var contact : Contact? //optional if nil add new contact
    var emails : [ContactEditEmail] = []
    var cells : [ContactEditPhone] = []
    var addresses : [ContactEditAddress] = []
    var informations : [ContactEditInformation] = []
    var fields : [ContactEditField] = []
    var notes : ContactEditNote = ContactEditNote(n_note: "")
    var profile : ContactEditProfile = ContactEditProfile(n_displayname: "")
    
    var origvCard2 : PMNIVCard?
    var origvCard3 : PMNIVCard?
    
    init(c : Contact?) {
        super.init()
        self.contact = c
        self.prepareContactData()
    }
    
    private func prepareContactData() {
        if let c = contact, c.managedObjectContext != nil {
            profile = ContactEditProfile(o_displayname: c.name)
            let cards = c.getCardData()
            for c in cards {
                switch c.type {
                case .PlainText:
                    if let vcard = PMNIEzvcard.parseFirst(c.data) {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let type = types.count > 0 ? types.first! : ""
                            let ce = ContactEditEmail(order: order, type:type, email:e.getValue(), isNew: false)
                            self.emails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .EncryptedOnly: break
                case .SignedOnly:
                    origvCard2 = PMNIEzvcard.parseFirst(c.data)
                    if let vcard = origvCard2 {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let type = types.count > 0 ? types.first! : ""
                            let ce = ContactEditEmail(order: order, type:type, email:e.getValue(), isNew: false)
                            self.emails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .SignAndEncrypt:
                    let pt_contact = sharedOpenPGP.decryptMessage(c.data, passphras: sharedUserDataService.mailboxPassword!)
                    origvCard3 = PMNIEzvcard.parseFirst(pt_contact)
                    if let vcard = origvCard3 {
                        let types = vcard.getPropertyTypes()
                        for type in types {
                            switch type {
                            case "Telephone":
                                let telephones = vcard.getTelephoneNumbers()
                                var order : Int = 1
                                for t in telephones {
                                    let types = t.getTypes()
                                    let type = types.count > 0 ? types.first! : ""
                                    let cp = ContactEditPhone(order: order, type:type, phone:t.getText(), isNew:false)
                                    self.cells.append(cp)
                                    order += 1
                                }
                                break
                            case "Address":
                                let addresses = vcard.getAddresses()
                                var order : Int = 1
                                for a in addresses {
                                    let types = a.getTypes()
                                    let type = types.count > 0 ? types.first! : ""
                                    
                                    let pobox = a.getPoBoxes().joined(separator: ",")
                                    let street = a.getStreetAddress()
                                    //let extention =
                                    let locality = a.getLocality()
                                    let region = a.getRegion()
                                    let postal = a.getPostalCode()
                                    let country = a.getCountry()
                                    
                                    let ca = ContactEditAddress(order: order, type: type, pobox: pobox, street: street,
                                                                locality: locality, region: region,
                                                                postal: postal, country: country, isNew: false)
                                    self.addresses.append(ca)
                                    order += 1
                                }
                                
                            case "Organization":
                                let org = vcard.getOrganization()
                                let info = ContactEditInformation(type: .organization, value:org?.getValue() ?? "")
                                self.informations.append(info)
                            case "Title":
                                let title = vcard.getTitle()
                                let info = ContactEditInformation(type: .title, value:title?.getTitle() ?? "")
                                self.informations.append(info)
                            case "Nickname":
                                let nick = vcard.getNickname()
                                let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "")
                                self.informations.append(info)
                            case "Birthday":
                                //                            let nick = vcard.ge
                                //                            let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "")
                                //                            origInformations.append(info)
                                break
                            case "Anniversary":
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
                                //case "Gender":
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
                            let type = t.getType()
                            let cp = ContactEditField(order: order, type: type, field: t.getValue(), isNew:false)
                         self.fields.append(cp)
                            order += 1
                        }
                        
                        if let note = vcard.getNote() {
                            let n = ContactEditNote(n_note: note.getNote())
                            n.isNew = false
                            self.notes = n
                        }
                    }
                    break
                }
            }
            
            
            
            
            
//            if let es = c.getEmailsArray() {
//                for i in 0 ..< es.count {
//                    let e = es[i]
//                    let ce = ContactEditEmail(o_order: i,o_type: e.type, o_email:e.email );
//                    emails.append(ce)
//                }
//            }
            
//            var emails : [ContactEditEmail] = []
//            var cells : [ContactEditPhone] = []
//            var addresses : [ContactEditAddress] = []
//            var orgs : [ContactEditOrg] = []
//            var fields : [ContactEditField] = []
//            var notes : ContactEditNote = ContactEditNote(n_note: "")
            
        } else {
            //TODO:: here should have a error pop
        }
    }
    
    override func getSections() -> [ContactEditSectionType] {
        return self.sections
    }
    override func sectionCount() -> Int {
        return sections.count
    }
    
    ///
    override func isNew() -> Bool {
        return contact == nil || contact!.managedObjectContext == nil
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
        let email = ContactEditEmail(order: emails.count, type: newType, email:"", isNew: true)
        emails.append(email)
        return email
    }
    
    override func deleteEmail(at index: Int) {
        if emails.count > index {
            emails.remove(at: index)
        }
    }
    
    override func newPhone() -> ContactEditPhone {
        let newType = getNewType(types: ContactPhoneType.allValues, typeInterfaces: cells)
        let cell = ContactEditPhone(order: emails.count, type: newType, phone:"", isNew:true)
        cells.append(cell)
        return cell
    }
    
    override func deletePhone(at index: Int) {
        if cells.count > index {
            cells.remove(at: index)
        }
    }
    
    override func newAddress() -> ContactEditAddress {
        let newType = getNewType(types: ContactAddressType.allValues, typeInterfaces: addresses)
        let addr = ContactEditAddress(order: emails.count, type: newType)
        addresses.append(addr)
        return addr
    }
    
    override func deleteAddress(at index: Int) {
        if addresses.count > index {
            addresses.remove(at: index)
        }
    }

    override func newInformation(type: InformationType) -> ContactEditInformation {
        let info = ContactEditInformation(type: type, value: "")
        self.informations.append(info)
        return info
    }
    
    override func deleteInformation(at index: Int) {
        if informations.count > index {
            informations.remove(at: index)
        }
    }
    
    override func newField() -> ContactEditField {
        let newType = getNewType(types: ContactFieldType.allValues, typeInterfaces: fields)
        let field = ContactEditField(order: emails.count, type: newType, field:"", isNew:true)
        fields.append(field)
        return field
    }
    
    override func deleteField(at index: Int) {
        if fields.count > index {
            fields.remove(at: index)
        }
    }
    
    override func done(complete : @escaping ContactEditSaveComplete) {
        if let c = contact, c.managedObjectContext != nil {
            //update
            var a_emails: [ContactEmail] = []
            for e in getOrigEmails() {
                a_emails.append(e.toContactEmail())
            }
            if origvCard2 == nil {
                origvCard2 = PMNIVCard.createInstance()
            }
            
            guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                return; //with error
            }
            
            var uid : PMNIUid? = nil
            var cards : [CardData] = []
            if let vcard2 = origvCard2 {
                if let fn = PMNIFormattedName.createInstance(profile.newDisplayName) {
                    vcard2.setFormattedName(fn)
                }
                
                //TODO::need to check the old email's group id
                var i : Int = 1;
                var newEmails:[PMNIEmail] = []
                for email in a_emails {
                    let group = "Item\(i)"
                    let m = PMNIEmail.createInstance(email.type, email: email.email, group: group)!
                    newEmails.append(m)
                    i += 1
                }
                //replace emails
                vcard2.setEmails(newEmails)
                
                //get uid first if null create a new one
                uid = vcard2.getUid()
                if uid == nil || uid!.getValue() == ""  {
                    let newuid = "protonmail-ios-" + UUID().uuidString
                    let uuid = PMNIUid.createInstance(newuid)
                    vcard2.setUid(uuid)
                    uid = uuid
                }
                
                // add others later
                let vcard2Str = PMNIEzvcard.write(vcard2)
                let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key, plainText: vcard2Str, passphras: sharedUserDataService.mailboxPassword!)
                
                //card 2 object
                let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
                
                cards.append(card2)
            }
          
            //start type 3 vcard
            var isCard3Set : Bool = false
            if origvCard3 == nil {
                origvCard3 = PMNIVCard.createInstance()
            }
            
            if let vcard3 = origvCard3 {
                var newCells:[PMNITelephone] = []
                for cell in cells {
                    let c = PMNITelephone.createInstance(cell.newType, number: cell.newPhone)!
                    newCells.append(c)
                    isCard3Set = true
                }
                //replace all cells
                if newCells.count > 0 {
                    vcard3.setTelephones(newCells)
                } else {
                    vcard3.clearTelephones()
                }
                
                var newAddrs:[PMNIAddress] = []
                for addr in addresses {
                    let a = PMNIAddress.createInstance(addr.newType,
                                                       street: addr.newStreet,
                                                       locality: addr.newLocality,
                                                       region: addr.newRegion,
                                                       zip: addr.newPostal,
                                                       country: addr.newCountry,
                                                       pobox: "")!
                    newAddrs.append(a)
                    isCard3Set = true
                }
                //replace all addresses
                if newAddrs.count > 0 {
                    vcard3.setAddresses(newAddrs)
                } else {
                    vcard3.clearAddresses()
                }
                
                vcard3.clearOrganizations()
                vcard3.clearNickname()
                vcard3.clearTitle()
                for info in informations {
                    switch info.infoType {
                    case .organization:
                        let org = PMNIOrganization.createInstance("", value: info.newValue)!
                        vcard3.setOrganizations([org])
                        isCard3Set = true
                    case .nickname:
                        let nn = PMNINickname.createInstance("", value: info.newValue)!
                        vcard3.setNickname(nn)
                        isCard3Set = true
                    case .title:
                        let t = PMNITitle.createInstance("", value: info.newValue)!
                        vcard3.setTitle(t)
                        isCard3Set = true
                    case .birthday:
                        break
                    case .anniversary:
                        break
                    }
                }
                
                
                if notes.newNote != "" {
                    let n = PMNINote.createInstance("", note: notes.newNote)!
                    vcard3.setNote(n)
                    isCard3Set = true
                }
                
                
                for field in fields{
                    let f = PMNIPMCustom.createInstance(field.newType, value: field.newField)
                    vcard3.add(f)
                    isCard3Set = true
                }
                
                if uid == nil || uid!.getValue() == "" {
                    let newuid = "protonmail-ios-" + UUID().uuidString
                    let uuid = PMNIUid.createInstance(newuid)
                    vcard3.setUid(uuid)
                    uid = uuid
                }
                
                let vcard3Str = PMNIEzvcard.write(vcard3)
                PMLog.D(vcard3Str);
                let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str)
                PMLog.D(encrypted_vcard3);
                let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                               plainText: vcard3Str,
                                                               passphras: sharedUserDataService.mailboxPassword!)
                //card 3 object
                let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
                if isCard3Set {
                    cards.append(card3)
                }
            }
            
            sharedContactDataService.update(contactID: c.contactID,
                                            cards: cards,
                                            completion: { (contacts : [Contact]?, error : NSError?) in
                                                if error == nil {
                                                    complete(nil)
                                                } else {
                                                    complete(error)
                                                }
            })
        } else {
            // pop error
        }
    }
    
    override func delete(complete: @escaping ContactEditSaveComplete) {
        if isNew() {
            complete(nil)
        } else {
            let contactID = contact?.contactID
            sharedContactDataService.delete(contactID: contactID!, completion: { (error) in
                if let err = error {
                    complete(err)
                } else {
                    complete(nil)
                }
            })
        }
    }
}
