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
        }
    }
    
    var type : String {
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
}


class ContactEditViewModel {
    
    var allowed_types: [InformationType] = [.organization,
                                            .nickname,
                                            .title]
    
    typealias ContactEditSaveComplete = ((_ error: NSError?) -> Void)

    public init() { }
    
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
            for info in getOrigInformations() {
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
    
    func getOrigInformations() -> [ContactEditInformation] {
        fatalError("This method must be overridden")
    }
    
    // check view is new or update
    func isNew() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getOrigEmails() -> [ContactEditEmail] {
         fatalError("This method must be overridden")
    }
    
    func getOrigCells() -> [ContactEditPhone] {
        fatalError("This method must be overridden")
    }
    
    func getOrigAddresses() -> [ContactEditAddress] {
        fatalError("This method must be overridden")
    }
    
    func getOrigFields() -> [ContactEditField] {
        fatalError("This method must be overridden")
    }
    
    func getOrigNotes() -> ContactEditNote {
        fatalError("This method must be overridden")
    }
    
    func getProfile() -> ContactEditProfile {
        fatalError("This method must be overridden")
    }
    
    //
    func newEmail() -> ContactEditEmail {
        fatalError("This method must be overridden")
    }
    func newPhone() -> ContactEditPhone {
        fatalError("This method must be overridden")
    }
    func newAddress() -> ContactEditAddress {
        fatalError("This method must be overridden")
    }
    func newInformation(type: InformationType) -> ContactEditInformation {
        fatalError("This method must be overridden")
    }
    func newField() -> ContactEditField {
        fatalError("This method must be overridden")
    }
    
    // actions
    func done(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
    
    func delete(complete : @escaping ContactEditSaveComplete) -> Void {
        fatalError("This method must be overridden")
    }
}


