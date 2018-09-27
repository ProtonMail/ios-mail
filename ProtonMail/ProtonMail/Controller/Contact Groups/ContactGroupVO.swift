//
//  ContactGroupVO.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/26.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupVO: NSObject, ContactPickerModelProtocol
{
    var modelType: ContactPickerModelState {
        get {
            return .contactGroup
        }
    }
    
    var ID: String
    var contactTitle: String
    var displayName: String?
    var displayEmail: String?
    var contactSubtitle: String?
    var contactImage: UIImage?
    var lock: UIImage?
    var hasPGPPined: Bool
    var hasNonePM: Bool
    
    func notes(type: Int) -> String {
        return ""
    }
    
    func setType(type: Int) { }
    
    func lockCheck(progress: () -> Void, complete: LockCheckComplete?) { }
    
    init(ID: String, name: String) {
        self.ID = ID
        contactTitle = name
        displayName = nil
        displayEmail = nil
        contactSubtitle = ""
        contactImage = nil
        lock = nil
        hasPGPPined = false
        hasNonePM = false
    }
}
