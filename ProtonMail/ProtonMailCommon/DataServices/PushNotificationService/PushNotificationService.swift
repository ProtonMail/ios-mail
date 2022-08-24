//
//  PushNotificationService.swift
//  Proton Mail
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
import UIKit
import UserNotifications
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_Common

class PushNotificationService: NSObject, Service, PushNotificationServiceProtocol {

    typealias SubscriptionSettings = PushSubscriptionSettings

    enum Key {
        static let subscription = "pushNotificationSubscription"
    }

    fileprivate var launchOptions: [AnyHashable: Any]?

    ///
    private let sessionIDProvider: SessionIdProvider
    private let deviceRegistrator: DeviceRegistrator
    private let signInProvider: SignInProvider
    private let unlockProvider: UnlockProvider
    private let deviceTokenSaver: Saver<String>
    private let sharedUserDefaults = SharedUserDefaults()
    private let notificationCenter: NotificationCenter
    private let navigationResolver: PushNavigationResolver

    private let unlockQueue = DispatchQueue(label: "PushNotificationService.unlock")

    init(subscriptionSaver: Saver<Set<SubscriptionWithSettings>> = KeychainSaver(key: Key.subscription),
         encryptionKitSaver: Saver<Set<PushSubscriptionSettings>> = PushNotificationDecryptor.saver,
         outdatedSaver: Saver<Set<SubscriptionSettings>> = PushNotificationDecryptor.outdater,
         sessionIDProvider: SessionIdProvider = AuthCredentialSessionIDProvider(),
         deviceRegistrator: DeviceRegistrator = PMAPIService.unauthorized, // unregister call is unauthorized; register call is authorized one, we will inject auth credentials into the call itself
         signInProvider: SignInProvider = SignInManagerProvider(),
         deviceTokenSaver: Saver<String> = PushNotificationDecryptor.deviceTokenSaver,
         unlockProvider: UnlockProvider = UnlockManagerProvider(),
         notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.currentSubscriptions = SubscriptionsPack(subscriptionSaver, encryptionKitSaver, outdatedSaver)
        self.sessionIDProvider = sessionIDProvider
        self.deviceRegistrator = deviceRegistrator
        self.signInProvider = signInProvider
        self.deviceTokenSaver = deviceTokenSaver
        self.unlockProvider = unlockProvider
        self.latestDeviceToken = KeychainWrapper.keychain.string(forKey: PushNotificationDecryptor.Key.deviceToken)
        self.notificationCenter = notificationCenter
        self.navigationResolver = PushNavigationResolver(
            dependencies: PushNavigationResolver.Dependencies(subscriptionsPack: currentSubscriptions)
        )

        super.init()

        defer {
            notificationCenter.addObserver(self, selector: #selector(didUnlockAsync), name: NSNotification.Name.didUnlock, object: nil)
            notificationCenter.addObserver(self, selector: #selector(didSignOut), name: NSNotification.Name.didSignOut, object: nil)
        }
    }

    fileprivate var latestDeviceToken: String? { // previous device tokens are not relevant for this class
        willSet {
            guard latestDeviceToken != newValue else { return }
            // Reset state if new token is changed.
            let settings = self.currentSubscriptions.settings()
            for setting in settings {
                self.currentSubscriptions.update(setting, toState: .notReported)
            }
        }
        didSet { self.deviceTokenSaver.set(newValue: latestDeviceToken)} // but we have to save one for PushNotificationDecryptor
    }
    fileprivate let currentSubscriptions: SubscriptionsPack

    // MARK: - register for notificaitons

    func registerForRemoteNotifications() {
        /// TODO::fixme we don't need to request this remote when start until logged in. we only need to register after user logged in
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        self.unreportOutdatedSettings()
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: String) {
        self.latestDeviceToken = deviceToken
        if self.signInProvider.isSignedIn, self.unlockProvider.isUnlocked {
            self.didUnlockAsync()
        }
    }

    @objc private func didUnlockAsync() {
        unlockQueue.async {
            self.didUnlock()    // cuz encryption kit generation can take significant time
        }
    }

    private func generateEncryptionKit(for settings: PushNotificationService.SubscriptionSettings) -> SubscriptionSettings {
        var newSettings = settings
        do {
            try newSettings.generateEncryptionKit()
        } catch let error {
            assert(false, "failed to generate enryption kit: \(error)")
        }
        return newSettings

    }

    private func finalizeReporting(settingsToReport: Set<PushNotificationService.SubscriptionSettings>) {
        self.unreportOutdatedSettings()
        let result = self.report(settingsToReport)

        PushNotificationService.updateSettingsIfNeeded(reportResult: result,
                                                       currentSubscriptions: currentSubscriptions.subscriptions) { [weak self] result in
            self?.currentSubscriptions.update(result.0, toState: result.1)
        }
    }

    private func didUnlock() {
        guard case let sessionIDs = self.sessionIDProvider.sessionIDs, let deviceToken = self.latestDeviceToken else {
            return
        }

        if self.signInProvider.isSignedIn == true {
            if sessionIDs.isEmpty {
                return
            }
        }

        let settingsWeNeedToHave = sessionIDs.map { SubscriptionSettings(token: deviceToken, UID: $0) }

        let settingsToUnreport = self.currentSubscriptions.settings().subtracting(Set(settingsWeNeedToHave))
        self.currentSubscriptions.outdate(settingsToUnreport)

        let subscriptionsToKeep = self.currentSubscriptions.subscriptions.filter {
            ($0.state == .reported || $0.state == .pending) &&
            !settingsToUnreport.contains($0.settings)
        }
        var settingsToReport = Set(settingsWeNeedToHave)

        settingsToReport = Set(settingsToReport.map { settings -> SubscriptionSettings in
            // Always report all settings to make sure we don't miss any
            // Those already reported will just be overridden, others will be registered
            if sharedUserDefaults.shouldRegisterAgain(for: settings.UID) {
                sharedUserDefaults.didRegister(for: settings.UID)
                // Regenerate a key pair if the extension failed to decrypt notification payload
                return generateEncryptionKit(for: settings)
            } else {
                if let alreadyReportedSetting = subscriptionsToKeep.first(where: { $0.settings == settings }),
                   alreadyReportedSetting.settings.encryptionKit != nil {
                    return alreadyReportedSetting.settings
                } else {
                    return generateEncryptionKit(for: settings)
                }
            }
        })

        finalizeReporting(settingsToReport: settingsToReport)
    }

    @objc private func didSignOut() {
        let settingsToUnreport = self.currentSubscriptions.subscriptions.compactMap { subscription -> SubscriptionSettings? in
            return subscription.state == .notReported ? nil : subscription.settings
        }
        self.currentSubscriptions.outdate(Set(settingsToUnreport))
        self.unreportOutdatedSettings()
    }

    // register on BE and validate local values
    private func report(_ settingsToReport: Set<SubscriptionSettings>) -> [SubscriptionSettings: SubscriptionState] {
        guard !Thread.isMainThread else {
            assertionFailure("Should not call this method on main thread.")
            return [:]
        }

        var reportResult: [SubscriptionSettings: SubscriptionState] = [:]

        let group = DispatchGroup()
        settingsToReport.forEach { settings in
            group.enter()
            let completion: CompletionBlock = { _, _, error in
                defer {
                    group.leave()
                }
                guard error == nil else {
                    reportResult[settings] = .notReported
                    return
                }
                reportResult[settings] = .reported
            }
            reportResult[settings] = .pending
            
            let auth = sharedServices.get(by: UsersManager.self).getUser(by: settings.UID)?.auth
            self.deviceRegistrator.device(registerWith: settings, authCredential: auth, completion: completion)
        }
        group.wait()
        return reportResult
    }

    // unregister on BE and validate local values
    private func unreportOutdatedSettings() {
        currentSubscriptions.outdatedSettings.forEach { setting in
            deviceRegistrator.deviceUnregister(setting) { [weak self] _, _, error in
                let tokenDeleted = (error == nil)
                let tokenUnrecognized = (error?.code == APIErrorCode.deviceTokenDoesNotExist
                                         || error?.code == APIErrorCode.deviceTokenIsInvalid)
                if tokenDeleted || tokenUnrecognized {
                    self?.currentSubscriptions.removed(setting)
                }
            }
        }
    }

    // MARK: - launch options

    func setLaunchOptions (_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let launchoption = launchOptions {
            if let remoteNotification = launchoption[UIApplication.LaunchOptionsKey.remoteNotification ] as? [AnyHashable: Any] {
                self.launchOptions = remoteNotification
            }
        }
    }

    func setNotificationOptions (_ userInfo: [AnyHashable: Any]?, fetchCompletionHandler completionHandler: @escaping () -> Void) {
        self.launchOptions = userInfo
        completionHandler()
    }

    func processCachedLaunchOptions() {
        if let options = self.launchOptions {
            self.didReceiveRemoteNotification(options, completionHandler: { })
        }
    }

    func hasCachedLaunchOptions() -> Bool {
        return self.launchOptions != nil
    }

    // MARK: - notifications

    private func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        guard
            let payload = pushNotificationPayload(userInfo: userInfo),
            shouldHandleNotification(payload: payload)
        else {
            completionHandler()
            return
        }
        launchOptions = nil
        completionHandler()
        navigationResolver.mapNotificationToDeepLink(payload) { [weak self] deeplink in
            self?.notificationCenter.post(name: .switchView, object: deeplink)
        }
    }

    // MARK: - Private methods

    private func pushNotificationPayload(userInfo: [AnyHashable: Any]) -> PushNotificationPayload? {
        do {
            return try PushNotificationPayload(userInfo: userInfo)
        } catch {
            let message = "Fail parsing push payload."
            let info = String(describing: error)
            SystemLogger.log(message: message, redactedInfo: info, category: .pushNotification, isError: true)
            return nil
        }
    }

    private func shouldHandleNotification(payload: PushNotificationPayload) -> Bool {
        guard sharedServices.get(by: UsersManager.self).hasUsers() && UnlockManager.shared.isUnlocked() else {
            return false
        }
        return payload.isLocalNotification || (!payload.isLocalNotification && isUserManagerReady(payload: payload))
    }

    /// Given how the application logic sets up some services at launch time, when a push notification awakes the app, UserManager might
    /// not be set up yet, even with an authenticated user. This function is a patch to be sure UserManager is ready when the app has been
    /// launched by a remote notification being tapped by the user.
    private func isUserManagerReady(payload: PushNotificationPayload) -> Bool {
        guard let uid = payload.uid else { return false }
        return sharedServices.get(by: UsersManager.self).getUser(by: uid) != nil
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if UnlockManager.shared.isUnlocked() { // unlocked
            self.didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
        } else if UIApplication.shared.applicationState == .inactive { // opened by push
            self.setNotificationOptions(userInfo, fetchCompletionHandler: completionHandler)
        } else {
            // app is locked and not opened from push - nothing to do here
            completionHandler()
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let options: UNNotificationPresentationOptions = [.alert, .sound]
        completionHandler(options)
    }
}

extension PushNotificationService {
    static func updateSettingsIfNeeded(reportResult: [PushNotificationService.SubscriptionSettings: PushNotificationService.SubscriptionState],
                                currentSubscriptions: Set<PushNotificationService.SubscriptionWithSettings>,
                                updateSubscriptionClosure: ((PushNotificationService.SubscriptionSettings, PushNotificationService.SubscriptionState)) -> Void) {

        for result in reportResult {
            // Check if the setting is already reported successfully before.
            // If that's the case, ignore the result to prevent the failing result overriding the successful registration before.
            let currentSubscription = currentSubscriptions.first(where: {$0.settings.UID == result.key.UID})
            let isReportedBefore = currentSubscription?.state == .reported
            let isEncryptionKitTheSame = currentSubscription?.settings.encryptionKit == result.key.encryptionKit

            if isReportedBefore && isEncryptionKitTheSame {
                continue
            } else {
                updateSubscriptionClosure((result.key, result.value))
            }
        }
    }
}

// MARK: - Dependency Injection sugar

protocol SessionIdProvider {
    var sessionIDs: [String] { get }
}

struct AuthCredentialSessionIDProvider: SessionIdProvider {
    var sessionIDs: [String] {
        return sharedServices.get(by: UsersManager.self).users.map { $0.auth.sessionID }
    }
}

protocol SignInProvider {
    var isSignedIn: Bool { get }
}
struct SignInManagerProvider: SignInProvider {
    var isSignedIn: Bool {
        return sharedServices.get(by: UsersManager.self).hasUsers()
    }
}

protocol UnlockProvider {
    var isUnlocked: Bool { get }
}
struct UnlockManagerProvider: UnlockProvider {
    var isUnlocked: Bool {
        return sharedServices.get(by: UnlockManager.self).isUnlocked()
    }
}

protocol DeviceRegistrator {
    func device(registerWith settings: PushSubscriptionSettings, authCredential: AuthCredential?, completion: CompletionBlock?)
    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping CompletionBlock)
}

extension PMAPIService: DeviceRegistrator {}
