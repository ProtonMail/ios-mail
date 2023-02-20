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
    case protection = 0
    case changePin = 1
    case autoLockTime = 2
    case appKeyProtection = 3
}

enum ProtectionType: Int {
    case none = 0
    case pinCode = 1
    case biometric = 2
}

final class SettingsLockViewModel: SettingsLockViewModelProtocol {
    var input: SettingsLockViewModelInput { self }
    var output: SettingsLockViewModelOutput { self }
    private weak var uiDelegate: SettingsLockUIProtocol?
    private let router: SettingsLockRouterProtocol
    private let dependencies: Dependencies

    private(set) var protectionItems: [ProtectionType] = [.none, .pinCode]
    private(set) var sections: [SettingLockSection] = [.protection, .changePin, .autoLockTime]

    init(router: SettingsLockRouterProtocol, dependencies: Dependencies) {
        self.router = router
        self.dependencies = dependencies

        switch dependencies.biometricStatus.biometricType {
        case .touchID, .faceID:
            protectionItems.append(.biometric)
        case .none:
            break
        }
    }

    private func updateProtectionItems() {
        let oldStatus = sections
        sections = [.protection]

        if isProtectionEnabled {
            if isBiometricEnabled {
                switch dependencies.biometricStatus.biometricType {
                case .none:
                    break
                case .touchID, .faceID:
                    dependencies.coreKeymaker.deactivate(PinProtection(pin: "doesnotmatter"))
                }
            } else if isPinCodeEnabled {
                sections.append(.changePin)
                dependencies.coreKeymaker.deactivate(BioProtection())

                if !oldStatus.contains(.changePin) {
                    // just set pin protection
                    dependencies.userPreferences.setLockTime(value: AutolockTimeout(rawValue: 15))
                }
            }

            if dependencies.userPreferences.isPinCodeEnabled || dependencies.userPreferences.isTouchIDEnabled {
                if dependencies.enableAppKeyFeature() {
                    sections.append(.appKeyProtection)
                }
                sections.append(.autoLockTime)
            }
        } else {
            if dependencies.userPreferences.isPinCodeEnabled {
                dependencies.coreKeymaker.deactivate(PinProtection(pin: "doesnotmatter"))
            }
            if dependencies.userPreferences.isTouchIDEnabled {
                dependencies.coreKeymaker.deactivate(BioProtection())
            }
        }
        uiDelegate?.reloadData()
    }

    private func enableBioProtection( completion: @escaping () -> Void) {
        dependencies.coreKeymaker.deactivate(PinProtection(pin: "doesnotmatter"))
        dependencies.coreKeymaker.activate(BioProtection()) { [unowned self] activated in
            if activated {
                dependencies.notificationCenter.post(name: .appLockProtectionEnabled, object: nil, userInfo: nil)
            }
            disableAppKey(completion: completion)
        }
    }

    private func disableProtection() {
        if dependencies.userPreferences.isPinCodeEnabled {
            dependencies.coreKeymaker.deactivate(PinProtection(pin: "doesnotmatter"))
        }
        if dependencies.userPreferences.isTouchIDEnabled {
            dependencies.coreKeymaker.deactivate(BioProtection())
        }
        if let randomProtection = RandomPinProtection.randomPin {
            dependencies.coreKeymaker.deactivate(randomProtection)
        }
        dependencies.userPreferences.setKeymakerRandomkey(key: nil)
        dependencies.notificationCenter.post(name: .appLockProtectionDisabled, object: nil, userInfo: nil)
    }

    private func enableAppKey() {
        if let randomProtection = RandomPinProtection.randomPin {
            dependencies.coreKeymaker.deactivate(randomProtection)
            dependencies.notificationCenter.post(name: .appKeyEnabled, object: nil, userInfo: nil)
        }
        dependencies.userPreferences.setKeymakerRandomkey(key: nil)
    }

    private func disableAppKey(completion: (() -> Void)? = nil) {
        dependencies.userPreferences.setKeymakerRandomkey(key: String.randomString(32))
        if let randomProtection = RandomPinProtection.randomPin {
            dependencies.coreKeymaker.activate(randomProtection) { [unowned self] success in
                guard success else { return }
                dependencies.notificationCenter.post(name: .appKeyDisabled, object: nil, userInfo: nil)
                completion?()
            }
        }
    }
}

extension SettingsLockViewModel: SettingsLockViewModelOutput {
    func setUIDelegate(_ delegate: SettingsLockUIProtocol) {
        self.uiDelegate = delegate
    }

    var autoLockTimeOptions: [Int] {
        [-1, 0, 1, 2, 5, 10, 15, 30, 60]
    }

    var biometricType: BiometricType {
        return dependencies.biometricStatus.biometricType
    }

    var isProtectionEnabled: Bool {
        return isPinCodeEnabled || isBiometricEnabled
    }

    var isPinCodeEnabled: Bool {
        return dependencies.userPreferences.isPinCodeEnabled
    }

    var isBiometricEnabled: Bool {
        return dependencies.userPreferences.isTouchIDEnabled
    }

    var isAppKeyEnabled: Bool {
        return dependencies.userPreferences.isAppKeyEnabled
    }
}

extension SettingsLockViewModel: SettingsLockViewModelInput {
    func viewWillAppear() {
        updateProtectionItems()
    }

    func didTapNoProtection() {
        disableProtection()
        updateProtectionItems()
    }

    func didTapPinProtection() {
        router.go(to: .pinCodeSetup)
    }

    func didTapBiometricProtection() {
        enableBioProtection { [unowned self] in
            updateProtectionItems()
        }
    }

    func didTapChangePinCode() {
        router.go(to: .pinCodeSetup)
    }

    func didChangeAppKeyValue(isNewStatusEnabled: Bool) {
        if isNewStatusEnabled {
            enableAppKey()
        } else {
            disableAppKey()
        }
    }

    func didPickAutoLockTime(value: Int) {
        dependencies.userPreferences.setLockTime(value: AutolockTimeout(rawValue: value))
    }
}

extension SettingsLockViewModel {

    struct Dependencies {
        let biometricStatus: BiometricStatusProvider
        let userPreferences: LockPreferences
        let coreKeymaker: KeymakerProtocol
        let notificationCenter: NotificationCenter
        let enableAppKeyFeature: () -> Bool

        init(
            biometricStatus: BiometricStatusProvider,
            userPreferences: LockPreferences = userCachedStatus,
            coreKeymaker: KeymakerProtocol = keymaker,
            notificationCenter: NotificationCenter = NotificationCenter.default,
            enableAppKeyFeature: @escaping () -> Bool = { true }
        ) {
            self.biometricStatus = biometricStatus
            self.userPreferences = userPreferences
            self.coreKeymaker = coreKeymaker
            self.notificationCenter = notificationCenter
            self.enableAppKeyFeature = enableAppKeyFeature
        }
    }
}

extension UserCachedStatus: LockPreferences {
    func setKeymakerRandomkey(key: String?) {
        keymakerRandomkey = key
    }

    func setLockTime(value: ProtonCore_Keymaker.AutolockTimeout) {
        lockTime = value
    }
}
