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
    
    var verifyType2 : Bool = false
    var verifyType3 : Bool = false
    
    init(c : Contact) {
        self.contact = c
    }
    
    override func statusType2() -> Bool {
        return verifyType2
    }
    
    override func statusType3() -> Bool {
        return verifyType3
    }
    
    override func hasEncryptedContacts() -> Bool {
        if self.getOrigCells().count > 0 {
            return true
        }
        if self.getOrigAddresses().count > 0 {
            return true
        }
        if self.getOrigInformations().count > 0 {
            return true
        }
        if self.getOrigFields().count > 0 {
            return true
        }
        if self.getOrigNotes().count > 0 {
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
                        let type = types.count > 0 ? types.first! : ""
                        let ce = ContactEditEmail(order: order, type:type, email:e.getValue(), isNew: false)
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
                        let type = types.count > 0 ? types.first! : ""
                        let ce = ContactEditEmail(order: order, type:type, email:e.getValue(), isNew: false)
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
                                let type = types.count > 0 ? types.first! : ""
                                let cp = ContactEditPhone(order: order, type:type, phone:t.getText(), isNew: false)
                                origTelephons.append(cp)
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
                        let cp = ContactEditField(order: order, type: type, field: t.getValue(), isNew: false)
                        origFields.append(cp)
                        order += 1
                    }
                    
                    if let note = vcard.getNote() {
                        let n = ContactEditNote(n_note: note.getNote())
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
    
    override func getOrigEmails() -> [ContactEditEmail] {
        return self.origEmails
    }
    
    override func getOrigCells() -> [ContactEditPhone] {
        return self.origTelephons
    }
    
    override func getOrigAddresses() -> [ContactEditAddress] {
        return self.origAddresses
    }
    
    override func getOrigInformations() -> [ContactEditInformation] {
        return self.origInformations
    }
    
    override func getOrigFields() -> [ContactEditField] {
        return self.origFields
    }
    
    override func getOrigNotes() -> [ContactEditNote] {
        return self.origNotes
    }
    
    override func getContact() -> Contact {
        return self.contact
    }
}
