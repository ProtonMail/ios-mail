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
    case enableProtection = 0
    case changePin = 1
    case bioProtection = 2
    case timing = 3
    
    var description: String {
        switch self {
        case .enableProtection:
            return "Protection"
        case .bioProtection:
            return "BIO"
        case .timing:
            return "Timing"
        default:
            return ""
        }
    }
}

enum BioLockTypeItem: Int, CustomStringConvertible {
    case touchid = 1
    case faceid = 2
    
    var description : String {
        switch self {
        case .touchid:
            return "Enable TouchID"
        case .faceid:
            return "Enable FaceID"
        }
    }
}

enum ProtectionItem: Int, CustomStringConvertible {
    case none = 0
    case pinCode = 1

    var description: String {
        switch self {
        case .none:
            return "None"
        case .pinCode:
            return "Pin Code"
        }
    }
}

protocol SettingsLockViewModel : AnyObject {
    var sections: [SettingLockSection] { get set }

    var protectionItems: [ProtectionItem] { get set }
    var bioLockItems: [BioLockTypeItem] { get set }
    
    var lockOn: Bool { get }
    var isTouchIDEnabled: Bool { get }
    var auto_logout_time_options: [Int] { get }
    var biometricType: BiometricType { get }

    func updateProtectionItems()
    func disableProtection()
    func getBioProtectionSectionTitle() -> String?
}

class SettingsLockViewModelImpl : SettingsLockViewModel {
    var protectionItems: [ProtectionItem] = [.none, .pinCode]
    var bioLockItems: [BioLockTypeItem] = [.touchid, .faceid]
    
    var sections: [SettingLockSection] = [.enableProtection, .changePin, .bioProtection, .timing]

    var biometricType: BiometricType {
        return self.biometricStatus.biometricType
    }
    
    private let biometricStatus: BiometricStatusProvider
    private let userCacheStatus: CacheStatusInject
    
    var lockOn: Bool {
        return self.userCacheStatus.isPinCodeEnabled
    }

    var isTouchIDEnabled: Bool {
        return self.userCacheStatus.isTouchIDEnabled
    }

    let auto_logout_time_options = [-1, 0, 1, 2, 5,
                                    10, 15, 30, 60]
    
    init(biometricStatus: BiometricStatusProvider, userCacheStatus: CacheStatusInject) {
        self.biometricStatus = biometricStatus
        self.userCacheStatus = userCacheStatus
    }
    
    func updateProtectionItems() {
        sections = [.enableProtection]
        bioLockItems = []
        
        if lockOn {
            sections.append(.changePin)
            switch self.biometricStatus.biometricType {
            case .none:
                break
            case .touchID:
                sections.append(.bioProtection)
                bioLockItems.append(.touchid)
                break
            case .faceID:
                sections.append(.bioProtection)
                bioLockItems.append(.faceid)
                break
            }
            if self.userCacheStatus.isPinCodeEnabled || self.userCacheStatus.isTouchIDEnabled {
                sections.append(.timing)
            }
        } else {
            if self.userCacheStatus.isPinCodeEnabled {
                keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
            }
            if self.userCacheStatus.isTouchIDEnabled {
                keymaker.deactivate(BioProtection())
            }
        }
    }

    func disableProtection() {
        if userCachedStatus.isPinCodeEnabled {
            keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
        }
        if userCachedStatus.isTouchIDEnabled {
            keymaker.deactivate(BioProtection())
        }
    }

    func getBioProtectionSectionTitle() -> String? {
        switch self.biometricStatus.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return nil
        }
    }
}
