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
import ProtonCoreKeymaker

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
    typealias Dependencies = HasBiometricStatusProvider
    & HasKeychain
    & HasKeyMakerProtocol
    & HasNotificationCenter
    & HasUserCachedStatus

    var input: SettingsLockViewModelInput { self }
    var output: SettingsLockViewModelOutput { self }
    private weak var uiDelegate: SettingsLockUIProtocol?
    private let router: SettingsLockRouterProtocol
    private let dependencies: Dependencies
    private let isAppKeyFeatureEnabled: () -> Bool

    private(set) var protectionItems: [ProtectionType] = [.none, .pinCode]
    private(set) var sections: [SettingLockSection] = [.protection, .changePin, .autoLockTime]

    private var bioProtection: BioProtection {
        BioProtection(keychain: dependencies.keychain)
    }

    init(
        router: SettingsLockRouterProtocol,
        dependencies: Dependencies,
        isAppKeyFeatureEnabled: @escaping () -> Bool = { true }
    ) {
        self.router = router
        self.dependencies = dependencies
        self.isAppKeyFeatureEnabled = isAppKeyFeatureEnabled

        switch dependencies.biometricStatusProvider.biometricType {
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
                switch dependencies.biometricStatusProvider.biometricType {
                case .none:
                    break
                case .touchID, .faceID:
                    LockPreventor.shared.performWhileSuppressingLock {
                        deactivatePinProtection()
                    }
                }
            } else if isPinCodeEnabled {
                sections.append(.changePin)
                LockPreventor.shared.performWhileSuppressingLock {
                    dependencies.keyMaker.deactivate(bioProtection)
                }

                if !oldStatus.contains(.changePin) {
                    // just set pin protection
                    didPickAutoLockTime(value: .minutes(15))
                }
            }

            if dependencies.keyMaker.isPinCodeEnabled || dependencies.keyMaker.isTouchIDEnabled {
                if isAppKeyFeatureEnabled() {
                    sections.append(.appKeyProtection)
                }
                sections.append(.autoLockTime)
            }
        } else {
            if dependencies.keyMaker.isPinCodeEnabled {
                LockPreventor.shared.performWhileSuppressingLock {
                    deactivatePinProtection()
                }
            }
            if dependencies.keyMaker.isTouchIDEnabled {
                LockPreventor.shared.performWhileSuppressingLock {
                    dependencies.keyMaker.deactivate(bioProtection)
                }
            }
        }
        uiDelegate?.reloadData()
    }

    private func enableBioProtection( completion: @escaping () -> Void) {
        LockPreventor.shared.performWhileSuppressingLock {
            deactivatePinProtection()
        }
        dependencies.keyMaker.activate(bioProtection) { [unowned self] activated in
            if activated {
                dependencies.notificationCenter.post(name: .appLockProtectionEnabled, object: nil, userInfo: nil)
            }
            disableAppKey(completion: completion)
        }
    }

    private func disableProtection() {
        LockPreventor.shared.performWhileSuppressingLock {
            if dependencies.keyMaker.isPinCodeEnabled {
                deactivatePinProtection()
            }
            if dependencies.keyMaker.isTouchIDEnabled {
                dependencies.keyMaker.deactivate(bioProtection)
            }
            if let randomProtection = dependencies.keychain.randomPinProtection {
                dependencies.keyMaker.deactivate(randomProtection)
            }
            dependencies.keychain[.keymakerRandomKey] = nil
            dependencies.notificationCenter.post(name: .appLockProtectionDisabled, object: nil, userInfo: nil)
        }
    }

    private func enableAppKey() {
        if let randomProtection = dependencies.keychain.randomPinProtection {
            LockPreventor.shared.performWhileSuppressingLock {
                dependencies.keyMaker.deactivate(randomProtection)
            }
            dependencies.notificationCenter.post(name: .appKeyEnabled, object: nil, userInfo: nil)
        }
        dependencies.keychain[.keymakerRandomKey] = nil
    }

    private func disableAppKey(completion: (() -> Void)? = nil) {
        dependencies.keychain[.keymakerRandomKey] = String.randomString(32)
        if let randomProtection = dependencies.keychain.randomPinProtection {
            dependencies.keyMaker.activate(randomProtection) { [unowned self] success in
                guard success else { return }
                dependencies.notificationCenter.post(name: .appKeyDisabled, object: nil, userInfo: nil)
                completion?()
            }
        }
    }

    private func deactivatePinProtection() {
        dependencies.keyMaker.deactivate(PinProtection(pin: "doesnotmatter", keychain: dependencies.keychain))
    }

    private func deactivateBioProtectionAfterPassing() {
        Task {
            try await dependencies.keyMaker.verify(protector: bioProtection)
            await MainActor.run {
                self.disableProtection()
                self.updateProtectionItems()
            }
        }
    }
}

extension SettingsLockViewModel: SettingsLockViewModelOutput {
    func setUIDelegate(_ delegate: SettingsLockUIProtocol) {
        self.uiDelegate = delegate
    }

    var autoLockTimeOptions: [AutolockTimeout] {
        [
            .never,
            .always,
            .minutes(1),
            .minutes(2),
            .minutes(5),
            .minutes(10),
            .minutes(15),
            .minutes(30),
            .minutes(60)
        ]
    }

    var biometricType: BiometricType {
        dependencies.biometricStatusProvider.biometricType
    }

    var isProtectionEnabled: Bool {
        return isPinCodeEnabled || isBiometricEnabled
    }

    var isPinCodeEnabled: Bool {
        dependencies.keyMaker.isPinCodeEnabled
    }

    var isBiometricEnabled: Bool {
        dependencies.keyMaker.isTouchIDEnabled
    }

    var selectedAutolockTimeout: AutolockTimeout {
        dependencies.keychain[.autolockTimeout]
    }

    var isAppKeyEnabled: Bool {
        dependencies.keyMaker.isAppKeyEnabled
    }
}

extension SettingsLockViewModel: SettingsLockViewModelInput {
    func viewWillAppear() {
        updateProtectionItems()
    }

    func didTapNoProtection() {
        if dependencies.keyMaker.isPinCodeEnabled {
            router.go(to: .pinCodeDisable)
        } else if isBiometricEnabled {
            deactivateBioProtectionAfterPassing()
        } else {
            disableProtection()
            updateProtectionItems()
        }
    }

    func didTapPinProtection() {
        if isBiometricEnabled {
            Task {
                try await dependencies.keyMaker.verify(protector: bioProtection)
                await MainActor.run {
                    self.router.go(to: .pinCodeSetup)
                }
            }
            return
        }

        if dependencies.keyMaker.isPinCodeEnabled {
            router.go(to: .changePinCode)
        } else {
            router.go(to: .pinCodeSetup)
        }
    }

    func didTapBiometricProtection() {
        enableBioProtection { [unowned self] in
            updateProtectionItems()
        }
    }

    func didTapChangePinCode() {
        router.go(to: .changePinCode)
    }

    func didChangeAppKeyValue(isNewStatusEnabled: Bool) {
        if isNewStatusEnabled {
            enableAppKey()
        } else {
            disableAppKey()
        }
    }

    func didPickAutoLockTime(value: AutolockTimeout) {
        dependencies.keychain[.autolockTimeout] = value
        dependencies.keyMaker.resetAutolock()
    }
}
