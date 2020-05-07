//
//  ContactEditViewModelImpl.swift
//  ProtonMail - Created on 5/3/17.
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



class ContactEditViewModelImpl : ContactEditViewModel {
    var sections : [ContactEditSectionType] = [.emails,
                                               .encrypted_header,
                                               .cellphone,
                                               .home_address,
                                               .url,
                                               .information,
                                               .notes,
                                               .delete]

    var contact : Contact? //optional if nil add new contact
    var emails : [ContactEditEmail] = []
    var cells : [ContactEditPhone] = []
    var addresses : [ContactEditAddress] = []
    var informations : [ContactEditInformation] = []
    var fields : [ContactEditField] = []
    var notes : ContactEditNote = ContactEditNote(note: "", isNew: false)
    var profile : ContactEditProfile = ContactEditProfile(n_displayname: "")
    var urls : [ContactEditUrl] = []
    var contactGroupData: [String:(name: String, color: String, count: Int)] = [:]
    var profilePicture: UIImage? = nil
    var origProfilePicture: UIImage? = nil
    
    var origvCard2 : PMNIVCard?
    var origvCard3 : PMNIVCard?
    
    init(c : Contact?, user: UserManager) {
        super.init(user: user)
        self.contact = c
        self.prepareContactData()
        self.prepareContactGroupData()
    }
    
    private func prepareContactGroupData() {
        let groups = self.user.labelService.getAllLabels(of: .contactGroup)

        for group in groups {
            contactGroupData[group.labelID] = (name: group.name, color: group.color, count: group.emails.count)
        }
    }
    
    private func prepareContactData() {
        if let c = contact, c.managedObjectContext != nil {
            profile = ContactEditProfile(o_displayname: c.name)
            let cards = c.getCardData()
            for c in cards.sorted(by: {$0.type.rawValue < $1.type.rawValue}) {
                switch c.type {
                case .PlainText:
                    PMLog.D(c.data)
                    if let vcard = PMNIEzvcard.parseFirst(c.data) {
                        let emails = vcard.getEmails()
                        var order : Int = 1
                        for e in emails {
                            let types = e.getTypes()
                            let typeRaw = types.count > 0 ? types.first! : ""
                            let type = ContactFieldType.get(raw: typeRaw)
                            
                            ///
                            let group = e.getGroup()
                            //get based on group
                            let keys = vcard.getKeys(group)
                            let encrypt = vcard.getPMEncrypt(group)
                            let sign = vcard.getPMSign(group)
                            let schemeType = vcard.getPMScheme(group)
                            let mimeType = vcard.getPMMimeType(group)
                            
                            let ce = ContactEditEmail(order: order,
                                                      type:type == .empty ? .email : type,
                                                      email:e.getValue(),
                                                      isNew: false,
                                                      keys: keys,
                                                      contactID: self.contact?.contactID,
                                                      encrypt: encrypt,
                                                      sign: sign,
                                                      scheme: schemeType,
                                                      mimeType: mimeType,
                                                      delegate: self)
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
                            let typeRaw = types.count > 0 ? types.first! : ""
                            let type = ContactFieldType.get(raw: typeRaw)
                            
                            ///
                            let group = e.getGroup()
                            //get based on group
                            let encrypt = vcard.getPMEncrypt(group)
                            let sign = vcard.getPMSign(group)
                            let keys = vcard.getKeys(group)
                            let schemeType = vcard.getPMScheme(group)
                            let mimeType = vcard.getPMMimeType(group)
                            
                            let ce = ContactEditEmail(order: order,
                                                      type:type == .empty ? .email : type,
                                                      email:e.getValue(),
                                                      isNew: false,
                                                      keys: keys,
                                                      contactID: self.contact?.contactID,
                                                      encrypt: encrypt,
                                                      sign: sign,
                                                      scheme: schemeType,
                                                      mimeType: mimeType,
                                                      delegate: self)
                            self.emails.append(ce)
                            order += 1
                        }
                    }
                    break
                case .SignAndEncrypt:
                    var pt_contact : String?
                    do {
                        pt_contact = try c.data.decryptMessage(binKeys:
                            self.user.userPrivateKeys,//contacts encrypted with UserKey
                            passphrase: self.user.mailboxPassword)
                    } catch {
                        //TODO::show error
                    }
                    
                    guard let pt_contact_vcard = pt_contact else {
                        break
                    }
                    
                    origvCard3 = PMNIEzvcard.parseFirst(pt_contact_vcard)
                    if let vcard = origvCard3 {
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
                                    let cp = ContactEditPhone(order: order, type:type == .empty ? .phone : type, phone:t.getText(), isNew:false)
                                    self.cells.append(cp)
                                    order += 1
                                }
                                break
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
                                    self.addresses.append(ca)
                                    order += 1
                                }
                                
                            case "Organization":
                                let org = vcard.getOrganization()
                                let info = ContactEditInformation(type: .organization, value:org?.getValue() ?? "", isNew: false)
                                self.informations.append(info)
                            case "Title":
                                let title = vcard.getTitle()
                                let info = ContactEditInformation(type: .title, value:title?.getTitle() ?? "", isNew: false)
                                self.informations.append(info)
                            case "Nickname":
                                let nick = vcard.getNickname()
                                let info = ContactEditInformation(type: .nickname, value:nick?.getNickname() ?? "", isNew: false)
                                self.informations.append(info)
                            case "Birthday":
                                let births = vcard.getBirthdays()
                                for b in births {
                                    let info = ContactEditInformation(type: .birthday, value:b.getText(), isNew: false)
                                    self.informations.append(info)
                                    break //only change first
                                }
                            case "Anniversary":
                                break
                            case "Gender":
                                if let gender = vcard.getGender() {
                                    let info = ContactEditInformation(type: .gender, value: gender.getGender(), isNew: false)
                                    self.informations.append(info)
                                }
                            case "Url":
                                let urls = vcard.getUrls()
                                var order : Int = 1
                                for url in urls {
                                    let typeRaw = url.getType()
                                    //let typeRaw = types.count > 0 ? types.first! : ""
                                    let type = ContactFieldType.get(raw: typeRaw)
                                    let cu = ContactEditUrl(order: order, type:type == .empty ? .url : type, url:url.getValue(), isNew: false)
                                    self.urls.append(cu)
                                    order += 1
                                }
                            case "Photo":
                                let photo = vcard.getPhoto()
                                print("photo", photo?.getEncodedData() ?? "",
                                      photo?.getRawData() ?? "",
                                      photo?.getImageType() ?? "",
                                      photo?.getIsBinary() ?? "")
                                if let image = photo?.getRawData() {
                                    let data = Data.init(bytes: image)
                                    self.profilePicture = UIImage.init(data: data)
                                    self.origProfilePicture = self.profilePicture
                                }
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
                            let typeRaw = t.getType()
                            let type = ContactFieldType.get(raw: typeRaw)
                            let cp = ContactEditField(order: order, type: type, field: t.getValue(), isNew:false)
                         self.fields.append(cp)
                            order += 1
                        }
                        
                        if let note = vcard.getNote() {
                            let n = ContactEditNote(note: note.getNote(), isNew: false)
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
        if let orig = self.origProfilePicture {
            return !orig.isEqual(self.profilePicture)
        } else {
            // orig is nil
            return self.profilePicture != nil
        }
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
                                     delegate: self)
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
        let cell = ContactEditPhone(order: emails.count, type: type, phone:"", isNew:true)
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
        let info = ContactEditInformation(type: type, value: "", isNew: true)
        self.informations.append(info)
        return info
    }
    
    override func deleteInformation(at index: Int) {
        if informations.count > index {
            informations.remove(at: index)
        }
    }
    
    override func newField() -> ContactEditField {
        let type = pick(newType: ContactFieldType.fieldTypes, pickedTypes: fields)
        let field = ContactEditField(order: emails.count, type: type, field:"", isNew:true)
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
            var cards : [CardData] = []
            
            // contact group, card type 0
            let vCard0 = PMNIVCard.createInstance()
            if let vCard0 = vCard0 {
                for (i, email) in getEmails().enumerated() {
                    let group = "ITEM\(i + 1)"
                    
                    let newCategories = PMNICategories.createInstance(group,
                                                                      value: email.getContactGroupNames())
                    vCard0.add(newCategories)
                }
                
                let vcard0Str = PMNIEzvcard.write(vCard0)
                PMLog.D(vcard0Str)
                let card0 = CardData(t: .PlainText,
                                     d: vcard0Str,
                                     s: "")
                
                cards.append(card0)
            }

            if origvCard2 == nil {
                origvCard2 = PMNIVCard.createInstance()
            }
            
            let userInfo = self.user.userInfo
            
            guard let userkey = userInfo.firstUserKey() else {
                return; //with error
            }
            
            var uid : PMNIUid? = nil
            if let vcard2 = origvCard2 {
                
                var defaultName = LocalString._general_unknown_title
                //TODO::need to check the old email's group id
                var i : Int = 1;
                var newEmails:[PMNIEmail] = []
                vcard2.clearEmails()
                vcard2.clearKeys()
                vcard2.clearPMSign()
                vcard2.clearPMEncrypt()
                vcard2.clearPMScheme()
                vcard2.clearPMMimeType()
                
                //update
                for email in getEmails() {
                    if email.newEmail.isEmpty || !email.newEmail.isValidEmail() {
                        complete(RuntimeError.invalidEmail.toError())
                        return
                    }
                    let group = "Item\(i)"
                    let em = email.newEmail
                    if !em.isEmpty {
                        defaultName = em
                        let m = PMNIEmail.createInstance(email.newType.vcardType, email: email.newEmail, group: group)!
                        newEmails.append(m)
                        
                        if let keys = email.keys {
                            for k in keys {
                                k.setGroup(group)
                                vcard2.add(k)
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
                        
                        i += 1
                    }
                }
                
                //replace emails
                vcard2.setEmails(newEmails)
                
                if let fn = PMNIFormattedName.createInstance(profile.newDisplayName.isEmpty ? defaultName : profile.newDisplayName) {
                    vcard2.setFormattedName(fn)
                }
                
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
                PMLog.D(vcard2Str);
                //TODO:: fix try later
                let signed_vcard2 = try? Crypto().signDetached(plainData: vcard2Str,
                                                              privateKey: userkey.private_key,
                                                              passphrase: user.mailboxPassword)
                
                //card 2 object
                let card2 = CardData(t: .SignedOnly,
                                     d: vcard2Str,
                                     s: signed_vcard2 ?? "")

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
                    if !cell.isEmpty() {
                        let c = PMNITelephone.createInstance(cell.newType.vcardType, number: cell.newPhone)!
                        newCells.append(c)
                        isCard3Set = true
                    }
                }
                //replace all cells
                if newCells.count > 0 {
                    vcard3.setTelephones(newCells)
                } else {
                    vcard3.clearTelephones()
                }
                
                var newAddrs:[PMNIAddress] = []
                for addr in addresses {
                    if !addr.isEmpty() {
                        let a = PMNIAddress.createInstance(addr.newType.vcardType,
                                                           street: addr.newStreet,
                                                           extendstreet: addr.newStreetTwo,
                                                           locality: addr.newLocality,
                                                           region: addr.newRegion,
                                                           zip: addr.newPostal,
                                                           country: addr.newCountry,
                                                           pobox: "")!
                        newAddrs.append(a)
                        isCard3Set = true
                    }
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
                vcard3.clearBirthdays()
                vcard3.clearGender()
                
                for info in informations {
                    if !info.isEmpty() {
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
                            let b = PMNIBirthday.createInstance("", date: info.newValue)!
                            vcard3.setBirthdays([b])
                            isCard3Set = true
                        case .anniversary:
                            //                        let a = PMNIAnniversary.createInstance("", date: info.newValue)!
                            //                        vcard3.seta
                            //                        isCard3Set = true
                            break
                        case .gender:
                            let g = PMNIGender.createInstance(info.newValue, text: "")!
                            vcard3.setGender(g)
                            isCard3Set = true
                        }
                    }
                }
                
                var newUrls:[PMNIUrl] = []
                for url in urls {
                    if !url.isEmpty() {
                        if let u = PMNIUrl.createInstance(url.newType.vcardType, value: url.newUrl) {
                            newUrls.append(u)
                            isCard3Set = true
                        }
                    }
                }
                //replace all urls
                if newUrls.count > 0 {
                    vcard3.setUrls(newUrls)
                } else {
                    vcard3.clearUrls()
                }
                
                let n = PMNINote.createInstance("", note: notes.newNote)!
                vcard3.setNote(n)
                isCard3Set = true
                
                for field in fields{
                    let f = PMNIPMCustom.createInstance(field.newType.vcardType, value: field.newField)
                    vcard3.add(f)
                    isCard3Set = true
                }
                
//                if uid == nil || uid!.getValue() == "" {
//                    let newuid = "protonmail-ios-" + UUID().uuidString
//                    let uuid = PMNIUid.createInstance(newuid)
//                    vcard3.setUid(uuid)
//                    uid = uuid
//                }
                
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
                
                let vcard3Str = PMNIEzvcard.write(vcard3)
                PMLog.D(vcard3Str);
                //TODO:: fix the try! later
                let encrypted_vcard3 = try! vcard3Str.encrypt(withPubKey: userkey.publicKey,
                                                              privateKey: "",
                                                              passphrase: "")
                let signed_vcard3 = try! Crypto().signDetached(plainData: vcard3Str,
                                                               privateKey: userkey.private_key,
                                                               passphrase: user.mailboxPassword)
                //card 3 object
                let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3!, s: signed_vcard3)
                if isCard3Set {
                    cards.append(card3)
                }
            }
            
            let completion = { (contacts : [Contact]?, error : NSError?) in
                if error == nil {
                    // we locally maintain the emailID by deleting all old ones
                    // and use the response to update the core data (see sharedContactDataService.update())
                    complete(nil)
                } else {
                    complete(error)
                }
            }
            
            self.user.contactService.update(contactID: c.contactID,
                                            cards: cards,
                                            completion: completion)
        } else {
            // pop error
        }
    }
    
    override func delete(complete: @escaping ContactEditSaveComplete) {
        if isNew() {
            complete(nil)
        } else {
            let contactID = contact?.contactID
            
            self.user.contactService.delete(contactID: contactID!, completion: { (error) in
                if let err = error {
                    complete(err)
                } else {
                    complete(nil)
                }
            })
        }
    }
    
    override func getAllContactGroupCounts() -> [(ID: String, name: String, color: String, count: Int)] {
        var result = self.contactGroupData.map{ return (ID:$0.key, name: $0.value.name, color: $0.value.color, count: $0.value.count) }
        result.sort(by: {$0.name < $1.name})
        return result
    }
    
    override func updateContactCounts(increase: Bool, contactGroups: Set<String>) {
        for group in contactGroups {
            if increase {
                if var value = contactGroupData[group] {
                    value.count = value.count + 1
                    contactGroupData.updateValue(value, forKey: group)
                } else {
                    // TODO: handle error
                }
            } else {
                if var value = contactGroupData[group] {
                    value.count = value.count - 1
                    contactGroupData.updateValue(value, forKey: group)
                } else {
                    // TODO: handle error
                }
            }
        }
    }
    
    // return the contact group that is empty after editing
    override func hasEmptyGroups() -> [String]? {
        var emptyGroupNames = [String]()
        for group in contactGroupData {
            if group.value.count == 0 {
                emptyGroupNames.append(group.value.name)
            }
        }
        
        return emptyGroupNames.count > 0 ? emptyGroupNames : nil
    }
}
