//
//  SettingsViewModel.swift
//  Proton Mail - Created on 12/12/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Keymaker

enum SettingLockSection: Int {
    case enableProtection = 0
    case changePin = 1
    case timing = 2
    case mainKey = 3

    var description: String {
        switch self {
        case .enableProtection:
            let title = "\n\nProtection"
            return LocalString._lock_wipe_desc + title
        case .timing:
            return "Timing"
        case .mainKey:
            return "Enable MainKey protection"
        default:
            return ""
        }
    }
}

enum ProtectionItem: Int, CustomStringConvertible {
    case none = 0
    case pinCode = 1
    case faceId = 2

    var description: String {
        switch self {
        case .none:
            return LocalString._security_protection_title_none
        case .pinCode:
            return LocalString._security_protection_title_pin
        case .faceId:
            return LocalString._security_protection_title_faceid
        }
    }
}

protocol SettingsLockViewModel: AnyObject {
    var sections: [SettingLockSection] { get set }

    var protectionItems: [ProtectionItem] { get set }

    var lockOn: Bool { get }
    var isTouchIDEnabled: Bool { get }
    var isPinCodeEnabled: Bool { get }
    var isAppKeyEnabled: Bool { get }
    var auto_logout_time_options: [Int] { get }
    var appPINTitle: String { get }

    func updateProtectionItems()
    func enableBioProtection( completion: @escaping () -> Void)
    func disableProtection()
    func getBioProtectionTitle() -> String
}

class SettingsLockViewModelImpl: SettingsLockViewModel {
    // Local feature flag to disable the random pin protection toggle
    private var enableRandomProtection = false
    var protectionItems: [ProtectionItem] = [.none, .pinCode]

    var sections: [SettingLockSection] = [.enableProtection, .changePin, .timing]

    var biometricType: BiometricType {
        return self.biometricStatus.biometricType
    }

    private let biometricStatus: BiometricStatusProvider
    private let userCacheStatus: CacheStatusInject

    var lockOn: Bool {
        return self.isPinCodeEnabled || self.isTouchIDEnabled
    }

    var isPinCodeEnabled: Bool {
        return self.userCacheStatus.isPinCodeEnabled
    }

    var isTouchIDEnabled: Bool {
        return self.userCacheStatus.isTouchIDEnabled
    }

    var isAppKeyEnabled: Bool {
        return self.userCacheStatus.isAppKeyEnabled
    }

    var appPINTitle: String {
        switch biometricType {
        case .faceID:
            return LocalString._app_pin_with_faceid
        case .touchID:
            return LocalString._app_pin_with_touchid
        default:
            return LocalString._app_pin
        }
    }

    let auto_logout_time_options = [-1, 0, 1, 2, 5,
                                    10, 15, 30, 60]

    init(biometricStatus: BiometricStatusProvider, userCacheStatus: CacheStatusInject) {
        self.biometricStatus = biometricStatus
        self.userCacheStatus = userCacheStatus

        switch self.biometricStatus.biometricType {
        case .touchID, .faceID:
            protectionItems.append(.faceId)
        case .none:
            break
        }
    }

    func updateProtectionItems() {
        let oldStatus = sections
        sections = [.enableProtection]

        if lockOn {
            if isTouchIDEnabled {
                switch self.biometricStatus.biometricType {
                case .none:
                    break
                case .touchID, .faceID:
                    keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
                }
            } else if isPinCodeEnabled {
                sections.append(.changePin)
                keymaker.deactivate(BioProtection())

                if !oldStatus.contains(.changePin) {
                    // just set pin protection
                    userCachedStatus.lockTime = AutolockTimeout(rawValue: 15)
                }
            }

            if self.userCacheStatus.isPinCodeEnabled || self.userCacheStatus.isTouchIDEnabled {
                sections.append(.timing)
                if self.enableRandomProtection {
                    sections.append(.mainKey)
                }
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

    func enableBioProtection( completion: @escaping () -> Void) {
        keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
        keymaker.activate(BioProtection()) { _ in
            completion()
        }
    }

    func disableProtection() {
        if userCachedStatus.isPinCodeEnabled {
            keymaker.deactivate(PinProtection(pin: "doesnotmatter"))
        }
        if userCachedStatus.isTouchIDEnabled {
            keymaker.deactivate(BioProtection())
        }
        if let randomProtection = RandomPinProtection.randomPin {
            keymaker.deactivate(randomProtection)
        }
        userCachedStatus.keymakerRandomkey = nil
    }

    func getBioProtectionTitle() -> String {
        switch self.biometricStatus.biometricType {
        case .faceID:
            return LocalString._security_protection_title_faceid
        case .touchID:
            return LocalString._security_protection_title_touchid
        default:
            return ""
        }
    }
}
