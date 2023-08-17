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
protocol PinFailedCountCache {
    var pinFailedCount: Int { get set }
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
    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    )
}

extension LAContext: LAContextProtocol {}

final class UnlockManager {
    weak var delegate: UnlockManagerDelegate?

    private(set) var cacheStatus: LockCacheStatus
    private let keyMaker: KeyMakerProtocol
    private let localAuthenticationContext: LAContextProtocol
    private let notificationCenter: NotificationCenter
    private var pinFailedCountCache: PinFailedCountCache

    init(
        cacheStatus: LockCacheStatus,
        keyMaker: KeyMakerProtocol,
        pinFailedCountCache: PinFailedCountCache,
        localAuthenticationContext: LAContextProtocol = LAContext(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.cacheStatus = cacheStatus
        self.keyMaker = keyMaker
        self.pinFailedCountCache = pinFailedCountCache

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
            pinFailedCountCache.pinFailedCount += 1
            completion(false)
            return
        }
        keyMaker.obtainMainKey(with: PinProtection(pin: userInputPin)) { key in
            guard self.validate(mainKey: key) else {
                self.pinFailedCountCache.pinFailedCount += 1
                completion(false)
                return
            }
            self.pinFailedCountCache.pinFailedCount = 0
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

    private func biometricAuthentication(requestMailboxPassword: @escaping () -> Void) {
        biometricAuthentication(afterBioAuthPassed: { self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword) })
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
                        requestPin()
                        self.biometricAuthentication(afterBioAuthPassed: {
                            self.unlockIfRememberedCredentials(requestMailboxPassword: requestMailboxPassword)
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
                            name: .didSignOutLastAccount,
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
        guard let delegate else {
            unlockFailed?()
            return
        }

        guard keyMaker.mainKeyExists(), delegate.isUserStored() else {
            delegate.setupCoreData()
            delegate.cleanAll {
                unlockFailed?()
            }
            return
        }

        guard delegate.isMailboxPasswordStored(forUser: uid) else { // this will provoke mainKey obtention
            delegate.setupCoreData()
            requestMailboxPassword()
            return
        }

        delegate.setupCoreData()

        pinFailedCountCache.pinFailedCount = 0

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
