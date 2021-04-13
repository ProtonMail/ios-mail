//
//  SettingsViewModel.swift
//  ProtonMail - Created on 12/12/18.
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
import PMKeymaker

enum SettingLockSection : Int, CustomStringConvertible {
    case lock = 0
    case type = 1
    case timer = 2
    
    var description : String {
        switch self {
        case .lock:
            return "Auto-lock app"
        case .timer:
            return "Auto-Lock Timer"
        default:
            return ""
        }
    }
    
    var foot : String {
        switch self {
        case .lock:
            switch UIDevice.current.biometricType {
            case .faceID:
                return "\(LocalString._lock_faceID_desc)\n\(LocalString._lock_wipe_desc)"
            default:
                return "\(LocalString._lock_touchID_desc) \n\(LocalString._lock_wipe_desc)"
            }
        default:
            return ""
        }
    }
}

enum LockTypeItem : Int, CustomStringConvertible {
    case pin = 0
    case touchid = 1
    case faceid = 2
    
    var description : String {
        switch(self){
        case .pin:
            return "Use PIN code"
        case .touchid:
            return "Use TouchID"
        case .faceid:
            return "Use FaceID"
        }
    }
}

protocol SettingsLockViewModel : AnyObject {
    var sections: [SettingLockSection] { get set }
    
    var lockItems: [LockTypeItem] {get set}
    
    var storageText : String { get }
    var recoveryEmail : String { get }
    
    var email : String { get }
    var displayName : String { get }
    
    var lockOn : Bool { get set }
    func updateProtectionItems() 
}

class SettingsLockViewModelImpl : SettingsLockViewModel {
    var lockItems: [LockTypeItem] = [.pin, .touchid, .faceid]
    
    var sections: [SettingLockSection] = [.lock, .type, .timer]
    
    var userManager: UserManager
    
    var lockOn: Bool = false
    
    init(user : UserManager) {
        self.userManager = user
        lockOn = userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled
//        self.updateProtectionItems()
    }
    
    var storageText: String {
        get {
            let usedSpace = self.userManager.userInfo.usedSpace
            let maxSpace = self.userManager.userInfo.maxSpace
            let formattedUsedSpace = ByteCountFormatter.string(fromByteCount: Int64(usedSpace), countStyle: ByteCountFormatter.CountStyle.binary)
            let formattedMaxSpace = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.binary)
            
            return "\(formattedUsedSpace)/\(formattedMaxSpace)"
        }
    }
    
    var recoveryEmail : String {
        get {
            return self.userManager.userInfo.notificationEmail
        }
    }
    
    
    var email : String {
        get {
            return self.userManager.defaultEmail
        }
        
    }
    var displayName : String {
        get {
            return self.userManager.defaultDisplayName
        }
    }
    
    func updateProtectionItems() {
        sections = [.lock]
        lockItems = []
        
        if lockOn {
            sections.append(.type)
            //TODO:: UIDevice is in UIkit. viewmodel should avoid UIKit. need to change this
            switch UIDevice.current.biometricType {
            case .none:
                break
            case .touchID:
                lockItems.append(.touchid)
                break
            case .faceID:
                lockItems.append(.faceid)
                break
            }
            lockItems.append(.pin)
            if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
                sections.append(.timer)
            }
        } else {
            if userCachedStatus.isPinCodeEnabled {
                keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
            }
            if userCachedStatus.isTouchIDEnabled {
                keymaker.deactivate(BioProtection())
            }
        }
    }
}
