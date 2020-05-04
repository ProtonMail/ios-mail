//
//  ContactEditVIewModel.swift
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

enum InformationType : Int {
    case organization = 0
    case nickname = 1
    case title = 2
    case birthday = 3
    case anniversary = 4
    case gender = 5
    
    var desc : String {
        switch self {
        case .organization:
            return LocalString._contacts_add_org
        case .nickname:
            return LocalString._contacts_add_nickname
        case .title:
            return LocalString._contacts_add_title
        case .birthday:
            return LocalString._contacts_add_bd
        case .anniversary:
            return LocalString._contacts_add_anniversary
        case .gender:
            return LocalString._contacts_add_gender
        }
    }
    
    var title : String {
        switch self {
        case .organization:
            return LocalString._contacts_info_organization
        case .nickname:
            return LocalString._contacts_info_nickname
        case .title:
            return LocalString._contacts_info_title
        case .birthday:
            return LocalString._contacts_info_birthday
        case .anniversary:
            return LocalString._contacts_info_anniversary
        case .gender:
            return LocalString._contacts_info_gender
        }
    }
}

enum ContactEditSectionType : Int {
    case display_name = 0
    case emails = 1
    case encrypted_header = 2
    case cellphone = 3
    case home_address = 4
    case information = 5  //org, birthday, anniversary, nickname, title and may add more prebuild types later.
    case custom_field = 6 //string field
    case notes = 7
    case delete = 8
    case upgrade = 9
    case share = 10
    case url = 11 //links
    case type2_warning = 12
    case type3_error = 13
    case type3_warning = 14
    case email_header = 15
    case debuginfo = 16
}



enum RuntimeError : Int, Error, CustomErrorVar {
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

class ContactEditViewModel: ContactEditViewModelContactGroupDelegate {
    
    var allowed_types: [InformationType] = [.organization,
                                            .nickname,
                                            .title,
                                            .gender,
                                            .birthday]
    
    typealias ContactEditSaveComplete = ((_ error: NSError?) -> Void)
    private(set) var user: UserManager
    public init(user: UserManager) {
        self.user = user
    }
    
    func paidUser() -> Bool {
        return user.isPaid
    }
    
    
    // table view 
    func getSections() -> [ContactEditSectionType] {
        fatalError("This method must be overridden")
    }
    func sectionCount() -> Int {
        fatalError("This method must be overridden")
    }
    
    func getLeftInfoTypes() -> [InformationType] {
        var out : [InformationType] = []
        for allowed in allowed_types {
            var found : Bool = false
            for info in getInformations() {
                if allowed == info.infoType {
                    found = true
                }
            }
            if !found {
                out.append(allowed)
            }
        }
        return out
    }
    
    func pick(newType supported: [ContactFieldType], pickedTypes: [ContactEditTypeInterface]) -> ContactFieldType {
        //TODO:: need to check the size
        var newType = supported[0] //get default
        for type in supported {
            var found = false
            for e in pickedTypes {
                if e.getCurrentType().rawString == type.rawString {
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
    
    
    func getInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }
    
    // check view is new or update
    func isNew() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getEmails() -> [ContactEditEmail] {
         fatalError("This method must be overridden")
    }
    
    func getCells() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }
    
    func getAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }
    
    func getFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }
    
    func getNotes() -> ContactEditNote {
        fatalError("This method must be overridden")
    }
    
    func getProfile() -> ContactEditProfile {
        fatalError("This method must be overridden")
    }
    
    func getProfilePicture() -> UIImage? {
        fatalError("This method must be overridden")
    }
    
    func setProfilePicture(image: UIImage?) {
        fatalError("This method must be overridden")
    }
    
    func profilePictureNeedsUpdate() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getUrls() -> [ContactEditUrl] {
        fatalError("This method must be overridden")
    }
    
    //
    func newUrl() -> ContactEditUrl {
        fatalError("This method must be overridden")
    }
    func deleteUrl(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    func newEmail() -> ContactEditEmail {
        fatalError("This method must be overridden")
    }
    func deleteEmail(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    
    func newPhone() -> ContactEditPhone {
        fatalError("This method must be overridden")
    }
    func deletePhone(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    
    func newAddress() -> ContactEditAddress {
        fatalError("This method must be overridden")
    }
    func deleteAddress(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    
    func newInformation(type: InformationType) -> ContactEditInformation {
        fatalError("This method must be overridden")
    }
    func deleteInformation(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    
    func newField() -> ContactEditField {
        fatalError("This method must be overridden")
    }
    func deleteField(at index : Int) -> Void {
        fatalError("This method must be overridden")
    }
    
    func needsUpdate() -> Bool {
        let profile = self.getProfile()
        if profile.needsUpdate() {
            return true
        }
        for e in getEmails() {
            if e.needsUpdate() {
                return true
            }
        }
        
        //encrypted part
        for cell in getCells() {
            if cell.needsUpdate() {
                return true
            }
        }
        for addr in getAddresses() {
            if addr.needsUpdate() {
                return true
            }
        }
        for info in getInformations() {
            if info.needsUpdate() {
                return true
            }
        }
        for url in getUrls() {
            if url.needsUpdate() {
                return true
            }
        }
        
        let note = getNotes()
        if note.needsUpdate() {
            return true
        }

        for field in getFields() {
            if field.needsUpdate() {
                return true
            }
        }
        
        if profilePictureNeedsUpdate() {
            return true
        }
        
        return false
    }
    
    // actions
    func done(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
    
    func delete(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
    
    // contact group
    func getAllContactGroupCounts() -> [(ID: String, name: String, color: String, count: Int)] {
        fatalError("This method must be overridden")
    }
    
    func updateContactCounts(increase: Bool, contactGroups: Set<String>) {
        fatalError("This method must be overridden")
    }
    
    func hasEmptyGroups() -> [String]? {
        fatalError("This method must be overridden")
    }
}


protocol ContactEditViewModelContactGroupDelegate {
    // contact group
    func getAllContactGroupCounts() -> [(ID: String, name: String, color: String, count: Int)]
    func updateContactCounts(increase: Bool, contactGroups: Set<String>)
}
