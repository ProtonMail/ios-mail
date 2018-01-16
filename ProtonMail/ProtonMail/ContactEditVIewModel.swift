//
//  ContactEditVIewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/3/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

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
            return NSLocalizedString("Add Organization", comment: "new contacts add Organization ")
        case .nickname:
            return NSLocalizedString("Add Nickname", comment: "new contacts add Nickname")
        case .title:
            return NSLocalizedString("Add Title", comment: "new contacts add Title")
        case .birthday:
            return NSLocalizedString("Add Birthday", comment: "new contacts add Birthday")
        case .anniversary:
            return NSLocalizedString("Add Anniversary", comment: "new contacts add Anniversary")
        case .gender:
            return NSLocalizedString("Add Gender", comment: "new contacts add Gender")
        }
    }
    
    var title : String {
        switch self {
        case .organization:
            return NSLocalizedString("Organization", comment: "contacts talbe cell Organization title")
        case .nickname:
            return NSLocalizedString("Nickname", comment: "contacts talbe cell Nickname title")
        case .title:
            return NSLocalizedString("Title", comment: "contacts talbe cell Title title")
        case .birthday:
            return NSLocalizedString("Birthday", comment: "contacts talbe cell Birthday title")
        case .anniversary:
            return NSLocalizedString("Anniversary", comment: "contacts talbe cell Anniversary title")
        case .gender:
            return NSLocalizedString("Gender", comment: "contacts talbe cell gender title")
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
}


class ContactEditViewModel {
    
    var allowed_types: [InformationType] = [.organization,
                                            .nickname,
                                            .title,
                                            .gender]
    
    typealias ContactEditSaveComplete = ((_ error: NSError?) -> Void)

    public init() { }
    
    func paidUser() -> Bool {
        if let role = sharedUserDataService.userInfo?.role, role > 0 {
            return true
        }
        return false
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
        
        return false
    }
    
    // actions
    func done(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
    
    func delete(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
}


