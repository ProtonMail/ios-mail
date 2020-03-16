//
//  ContactAddViewModelImpl.swift
//  ProtonMail - Created on 9/13/17.
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


class ContactAddViewModelImpl : ContactEditViewModel {
    var sections: [ContactEditSectionType] = [.emails,
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
    var profilePicture: UIImage? = nil

    override init(user: UserManager) {
        super.init(user: user)
        self.contact = nil
    }
    
    init(contactVO : ContactVO, user: UserManager) {
        super.init(user: user)
        self.contact = nil
        
        let email = self.newEmail()
        email.newEmail = contactVO.displayEmail ?? ""
        
        profile.newDisplayName = contactVO.displayName ?? ""
        
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
    
    override func getProfilePicture() -> UIImage? {
        return self.profilePicture
    }
    
    override func setProfilePicture(image: UIImage?) {
        self.profilePicture = image
    }
    
    override func profilePictureNeedsUpdate() -> Bool {
        return self.profilePicture != nil
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
        let email = ContactEditEmail(order: emails.count,
                                     type: type,
                                     email:"",
                                     isNew: true,
                                     keys: nil,
                                     contactID: self.contact?.contactID,
                                     encrypt: nil,
                                     sign: nil ,
                                     scheme: nil,
                                     mimeType: nil,
                                     delegate: nil)
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
        let mailboxPassword = user.mailboxPassword
        guard let userkey = user.userInfo.firstUserKey(),
            case let authCredential = user.authCredential else
        {
            complete(NSError.lockError())
            return
        }
        
        //add
        var a_emails: [ContactEmail] = []
        for e in getEmails() {
            if e.newEmail.isEmpty || !e.newEmail.isValidEmail() {
                complete(RuntimeError.invalidEmail.toError())
                return
            }
            a_emails.append(e.toContactEmail())
        }
        guard let vcard2 = PMNIVCard.createInstance() else {
            return; //with error
        }
        
        var defaultName = LocalString._general_unknown_title
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
        PMLog.D(vcard2Str)
        //TODO:: fix the try?
        let signed_vcard2 = try? Crypto().signDetached(plainData: vcard2Str,
                                                       privateKey: userkey.private_key,
                                                       passphrase: mailboxPassword)
        //card 2 object
        let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2 ?? "")
        
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
            if !addr.isEmpty() {
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
        
        // profile image
        vcard3.clearPhotos()
        if let profilePicture = profilePicture,
            let compressedImage = UIImage.resize(image: profilePicture,
                                                 targetSize: CGSize.init(width: 60, height: 60)),
            let jpegData = compressedImage.jpegData(compressionQuality: 0.5) {
            let image = PMNIPhoto.createInstance(jpegData,
                                                 type: "JPEG",
                                                 isBinary: true)
            vcard3.setPhoto(image)
            isCard3Set = true
        }
        
        vcard3.setUid(uuid)
        
        let vcard3Str = PMNIEzvcard.write(vcard3)
        PMLog.D(vcard3Str)
        //TODO:: fix the try!
        let encrypted_vcard3 = try! vcard3Str.encrypt(withPubKey: userkey.publicKey, privateKey: "", passphrase: "")
        PMLog.D(encrypted_vcard3 ?? "")
        let signed_vcard3 = try! Crypto().signDetached(plainData: vcard3Str,
                                                       privateKey: userkey.private_key,
                                                       passphrase: mailboxPassword)
        //card 3 object
        let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3 ?? "", s: signed_vcard3 )
        
        var cards : [CardData] = [card2]
        if isCard3Set {
            cards.append(card3)
        }
        //TODO:: can be improved
        user.contactService.add(cards: [cards], authCredential: authCredential) { (contacts : [Contact]?, error : NSError?) in
            if error == nil {
                complete(nil)
            } else {
                complete(error)
            }
        }
    }
    
    override func delete(complete: @escaping ContactEditViewModel.ContactEditSaveComplete) {
        complete(nil)
    }
}
