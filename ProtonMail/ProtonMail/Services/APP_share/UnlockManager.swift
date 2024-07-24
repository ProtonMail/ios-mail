//
//  UnlockManager.swift
//  Proton Mail - Created on 02/11/2018.
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
import LocalAuthentication
import ProtonCoreKeymaker
import ProtonMailAnalytics
#if !APP_EXTENSION
import LifetimeTracker
import ProtonCorePayments
#endif

enum SignInUIFlow: Int {
    case requirePin = 0
    case requireTouchID = 1
    case restore = 2
}

// sourcery: mock
protocol UnlockManagerDelegate: AnyObject {
    func cleanAll(completion: @escaping () -> Void)
    func isUserStored() -> Bool
    func isMailboxPasswordStoredForActiveUser() -> Bool
    func setupCoreData() throws
    func loadUserDataAfterUnlock()
}

// sourcery: mock
protocol LAContextProtocol: AnyObject {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
}

extension LAContext: LAContextProtocol {}

final class UnlockManager {
    weak var delegate: UnlockManagerDelegate?

    private(set) var cacheStatus: LockCacheStatus
    private let keychain: Keychain
    private let keyMaker: KeyMakerProtocol
    private let localAuthenticationContext: LAContextProtocol
    private let notificationCenter: NotificationCenter
    private let userDefaults: UserDefaults

    init(
        cacheStatus: LockCacheStatus,
        keychain: Keychain,
        keyMaker: KeyMakerProtocol,
        localAuthenticationContext: LAContextProtocol = LAContext(),
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter = .default
    ) {
        self.cacheStatus = cacheStatus
        self.keychain = keychain
        self.keyMaker = keyMaker

        self.localAuthenticationContext = localAuthenticationContext
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults

        #if !APP_EXTENSION
        trackLifetime()
        #endif
    }

    func isUnlocked() -> Bool {
        return validate(mainKey: keyMaker.mainKey(by: nil))
    }

    func getUnlockFlow() -> SignInUIFlow {
        migrateProtectionSetting()
        if cacheStatus.isPinCodeEnabled {
            return SignInUIFlow.requirePin
        }
        if cacheStatus.isTouchIDEnabled {
            return SignInUIFlow.requireTouchID
        }
        return SignInUIFlow.restore
    }

    func match(userInputPin: String, completion: @escaping (Bool) -> Void) {
        guard !userInputPin.isEmpty else {
            userDefaults[.pinFailedCount] += 1
            completion(false)
            return
        }
        keyMaker.obtainMainKey(with: PinProtection(pin: userInputPin, keychain: keychain)) { key in
            guard self.validate(mainKey: key) else {
                self.userDefaults[.pinFailedCount] += 1
                completion(false)
                return
            }
            self.userDefaults[.pinFailedCount] = 0
            completion(true)
        }
    }

    private func migrateProtectionSetting() {
        if cacheStatus.isPinCodeEnabled && cacheStatus.isTouchIDEnabled {
            _ = keyMaker.deactivate(PinProtection(pin: "doesnotmatter", keychain: keychain))
        }
    }

    private func validate(mainKey: MainKey?) -> Bool {
        guard let _ = mainKey else { // currently enough: key is Array and will be nil in case it was unlocked incorrectly
            keyMaker.lockTheApp() // remember to remove invalid key in case validation will become more complex
            return false
        }
        return true
    }

    private var isRequestingBiometricAuthentication: Bool = false
    func biometricAuthentication(afterBioAuthPassed: @escaping () -> Void) {
        var error: NSError?
        guard localAuthenticationContext.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            assertionFailure("LAContext canEvaluatePolicy is false")
            return
        }

        guard !isRequestingBiometricAuthentication else { return }
        isRequestingBiometricAuthentication = true
        keyMaker.obtainMainKey(with: BioProtection(keychain: keychain)) { key in
            defer {
                self.isRequestingBiometricAuthentication = false
            }
            guard self.validate(mainKey: key) else { return }
            afterBioAuthPassed()
        }
    }

    func unlockIfRememberedCredentials(
        requestMailboxPassword: () -> Void,
        unlockFailed: (() -> Void)? = nil,
        unlocked: (() -> Void)? = nil
    ) {
        guard let delegate else {
            SystemLogger.log(message: "UnlockManager delegate is nil", category: .loginUnlockFailed, isError: true)
            unlockFailed?()
            return
        }

        guard keyMaker.mainKeyExists(), delegate.isUserStored() else {
            let message = "UnlockManager mainKeyExists: \(keyMaker.mainKeyExists()), userStored: \(delegate.isUserStored())"
            SystemLogger.log(message: message, category: .loginUnlockFailed, isError: true)

            do {
                try delegate.setupCoreData()
            } catch {
                fatalError("\(error)")
            }

            delegate.cleanAll {
                unlockFailed?()
            }
            return
        }

        guard delegate.isMailboxPasswordStoredForActiveUser() else { // this will provoke mainKey obtention
            do {
                try delegate.setupCoreData()
            } catch {
                fatalError("\(error)")
            }

            requestMailboxPassword()
            return
        }

        do {
            try delegate.setupCoreData()
        } catch {
            fatalError("\(error)")
        }

        userDefaults[.pinFailedCount] = 0

        delegate.loadUserDataAfterUnlock()

        notificationCenter.post(name: Notification.Name.didUnlock, object: nil) // needed for app unlock
        unlocked?()
    }
}

#if !APP_EXTENSION
extension UnlockManager: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
