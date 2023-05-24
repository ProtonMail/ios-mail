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
import ProtonCore_Keymaker
import ProtonMailAnalytics
#if !APP_EXTENSION
import LifetimeTracker
import ProtonCore_Payments
#endif

enum SignInUIFlow: Int {
    case requirePin = 0
    case requireTouchID = 1
    case restore = 2
}

// sourcery: mock
protocol CacheStatusInject {
    var isPinCodeEnabled: Bool { get }
    var isTouchIDEnabled: Bool { get }
    var isAppKeyEnabled: Bool { get }
    var pinFailedCount: Int { get set }

    /// Returns `true` if there is some kind of protection to access the app, but
    /// the main key is accessible without the user having to interact to unlock the app.
    var isAppLockedAndAppKeyDisabled: Bool { get }

    /// Returns `true` if there is some kind of protection to access the app, and
    /// the main key is only accessible if user interacts to unlock the app (e.g. enters pin, uses FaceID,...)
    var isAppLockedAndAppKeyEnabled: Bool { get }
}

// sourcery: mock
protocol UnlockManagerDelegate: AnyObject {
    func cleanAll(completion: @escaping () -> Void)
    func isUserStored() -> Bool
    func isMailboxPasswordStored(forUser uid: String?) -> Bool
    func setupCoreData()
    func loadUserDataAfterUnlock()
}

// sourcery: mock
protocol LAContextProtocol: AnyObject {
    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool
}

extension LAContext: LAContextProtocol {}

final class UnlockManager: Service {
    private var cacheStatus: CacheStatusInject
    unowned let delegate: UnlockManagerDelegate
    private let keyMaker: KeyMakerProtocol
    private let localAuthenticationContext: LAContextProtocol
    private let notificationCenter: NotificationCenter

    static var shared: UnlockManager {
        return sharedServices.get(by: UnlockManager.self)
    }

    init(
        cacheStatus: CacheStatusInject,
        delegate: UnlockManagerDelegate,
        keyMaker: KeyMakerProtocol,
        localAuthenticationContext: LAContextProtocol = LAContext(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.cacheStatus = cacheStatus
        self.delegate = delegate
        self.keyMaker = keyMaker
        self.localAuthenticationContext = localAuthenticationContext
        self.notificationCenter = notificationCenter

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
            cacheStatus.pinFailedCount += 1
            completion(false)
            return
        }
        keyMaker.obtainMainKey(with: PinProtection(pin: userInputPin)) { key in
            guard self.validate(mainKey: key) else {
                userCachedStatus.pinFailedCount += 1
                completion(false)
                return
            }
            self.cacheStatus.pinFailedCount = 0
            completion(true)
        }
    }

    private func migrateProtectionSetting() {
        if cacheStatus.isPinCodeEnabled && cacheStatus.isTouchIDEnabled {
            _ = keyMaker.deactivate(PinProtection(pin: "doesnotmatter"))
        }
    }

    private func validate(mainKey: MainKey?) -> Bool {
        guard let _ = mainKey else { // currently enough: key is Array and will be nil in case it was unlocked incorrectly
            keyMaker.lockTheApp() // remember to remove invalid key in case validation will become more complex
            return false
        }
        return true
    }

    func biometricAuthentication(requestMailboxPassword: @escaping () -> Void) {
        biometricAuthentication(afterBioAuthPassed: { self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword) })
    }

    var isRequestingBiometricAuthentication: Bool = false
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
        keyMaker.obtainMainKey(with: BioProtection()) { key in
            defer {
                self.isRequestingBiometricAuthentication = false
            }
            guard self.validate(mainKey: key) else { return }
            afterBioAuthPassed()
        }
    }

    func initiateUnlock(
        flow signInFlow: SignInUIFlow,
        requestPin: @escaping () -> Void,
        requestMailboxPassword: @escaping () -> Void
    ) {
        if cacheStatus.isAppLockedAndAppKeyDisabled {
            unlockIfRememberedCredentials(
                requestMailboxPassword: requestMailboxPassword,
                unlocked: {
                    switch signInFlow {
                    case .requirePin:
                        requestPin()
                    case .requireTouchID:
                        self.biometricAuthentication(afterBioAuthPassed: {
                            self.unlockIfRememberedCredentials(
                                requestMailboxPassword: requestMailboxPassword,
                                unlocked: {
                                    self.notificationCenter.post(name: Notification.Name.didUnlock, object: nil)
                                }
                            )
                        })
                    case .restore:
                        assertionFailure("Should not reach here.")
                    }
                }
            )
        } else {
            switch signInFlow {
            case .requirePin:
                requestPin()
            case .requireTouchID:
                biometricAuthentication(requestMailboxPassword: requestMailboxPassword)
            case .restore:
                unlockIfRememberedCredentials(
                    requestMailboxPassword: requestMailboxPassword,
                    unlockFailed: {
                        self.notificationCenter.post(
                            name: Notification.Name.didSignOut,
                            object: nil
                        )
                    }
                )
            }
        }
    }

    func unlockIfRememberedCredentials(
        forUser uid: String? = nil,
        requestMailboxPassword: () -> Void,
        unlockFailed: (() -> Void)? = nil,
        unlocked: (() -> Void)? = nil
    ) {
        Breadcrumbs.shared.add(message: "UnlockManager.unlockIfRememberedCredentials called", to: .randomLogout)
        guard keyMaker.mainKeyExists(), delegate.isUserStored() else {
            delegate.setupCoreData()
            delegate.cleanAll {
                unlockFailed?()
            }
            return
        }

        guard self.delegate.isMailboxPasswordStored(forUser: uid) else { // this will provoke mainKey obtention
            delegate.setupCoreData()
            requestMailboxPassword()
            return
        }

        delegate.setupCoreData()

        cacheStatus.pinFailedCount = 0

        delegate.loadUserDataAfterUnlock()

        if !cacheStatus.isTouchIDEnabled && !cacheStatus.isPinCodeEnabled {
            notificationCenter.post(name: Notification.Name.didUnlock, object: nil) // needed for app unlock
        }
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
