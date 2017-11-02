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
                                               .custom_field,
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
                            let ce = ContactEditEmail(n_order: order, n_type:type, n_email:e.getValue())
                            self.emails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .EncryptedOnly: break
                case .SignedOnly:
                    if let vcard = PMNIEzvcard.parseFirst(c.data) {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let type = types.count > 0 ? types.first! : ""
                            let ce = ContactEditEmail(n_order: order, n_type:type, n_email:e.getValue())
                            self.emails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .SignAndEncrypt:
                    let pt_contact = sharedOpenPGP.decryptMessage(c.data, passphras: sharedUserDataService.mailboxPassword!)
                    if let vcard = PMNIEzvcard.parseFirst(pt_contact) {
                        let types = vcard.getPropertyTypes()
                        for type in types {
                            switch type {
                            case "Telephone":
                                let telephones = vcard.getTelephoneNumbers()
                                var order : Int = 1
                                for t in telephones {
                                    let types = t.getTypes()
                                    let type = types.count > 0 ? types.first! : ""
                                    let cp = ContactEditPhone(n_order: order, n_type:type, n_phone:t.getText())
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
                                    let address = a.getPoBoxes().joined(separator: ",")
                                    let ca = ContactEditAddress(n_order: order, n_type:type, n_street:address)
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
                            let cp = ContactEditField(n_order: order, n_type: type, n_field: t.getValue() )
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
        let info = ContactEditInformation(type: type, value: "")
        self.informations.append(info)
        return info
    }
    
    override func newField() -> ContactEditField {
        let newType = getNewType(types: ContactFieldType.allValues, typeInterfaces: fields)
        let field = ContactEditField(n_order: emails.count, n_type: newType, n_field:"")
        fields.append(field)
        return field
    }
    
    override func done(complete : @escaping ContactEditSaveComplete) {
        if let c = contact, c.managedObjectContext != nil {
            
            //profile.
            var contactDisplayName : String? = nil
            if profile.needsUpdate() {
                contactDisplayName = profile.newDisplayName
            }
            
            //update
//            var a_emails: [ContactEmail] = []
//            for e in getOrigEmails() {
//                a_emails.append(e.toContactEmail())
//            }
//            //            let a_data: ContactDate
//            guard let vcard = PMNIVCard.createInstance() else {
//                return; //with error
//            }
//            
//            if let fn = PMNIFormattedName.createInstance(profile.newDisplayName) {
//                vcard.setFormattedName(fn)
//            }
//            
//            for email in a_emails {
//                let m = PMNIEmail.createInstance(email.type, email: email.email)
//                vcard.add(m)
//            }
//            
//            // add others later
//            
//            let vcardStr = PMNIEzvcard.write(vcard)
//            guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
//                return; //with error
//            }
//            PMLog.D(vcardStr);
//            let encrypted_vcard = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcardStr)
//            PMLog.D(encrypted_vcard);
//            
//            let contactData : ContactData = ContactData(d: encrypted_vcard, t: 1)
            
            sharedContactDataService.updateContact(contactid: c.contactID,
                                                   name: contactDisplayName,
                                                   emails: nil,
                                                   cards: nil,
                                                   completion: { (contactRes: Contact?, error : NSError?) in
                                                        if error == nil {
                                                            complete(nil)
                                                        } else {
                                                            complete(error)
                                                        }
                                                    })
        } else {
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
            
            sharedContactDataService.addContact(name: profile.newDisplayName,
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
        

        
        
        
    }
    
    override func delete(complete: @escaping ContactEditViewModel.ContactEditSaveComplete) {
        if isNew() {
            complete(nil)
        } else {
            let contactID = contact?.contactID
            sharedContactDataService.deleteContact(contactID!, completion: { (error) in
                if let err = error {
                    complete(err)
                } else {
                    complete(nil)
                }
            })
        }
    }
}
