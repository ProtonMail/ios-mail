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
import ProtonCore_Common
import ProtonCore_Networking
import ProtonCore_Services
import UIKit
import UserNotifications

class PushNotificationService: NSObject, Service, PushNotificationServiceProtocol {
    typealias SubscriptionSettings = PushSubscriptionSettings
    typealias UpdateSubscriptionTuple = (SubscriptionSettings, SubscriptionState)

    private let currentSubscriptions: SubscriptionsPack
    private let deviceRegistrator: DeviceRegistrator
    private let navigationResolver: PushNavigationResolver
    private let notificationActions: PushNotificationActionsHandler
    private let notificationCenter: NotificationCenter
    private let sessionIDProvider: SessionIdProvider
    private let sharedUserDefaults = SharedUserDefaults()
    private let signInProvider: SignInProvider
    private let unlockProvider: UnlockProvider
    private let deviceTokenSaver: Saver<String>
    private let unlockQueue = DispatchQueue(label: "PushNotificationService.unlock")

    /// The notification action is pending because the app has been just launched and can't make a request yet
    private var notificationActionPendingUnlock: PendingNotificationAction?
    private var notificationOptions: [AnyHashable: Any]?
    private var latestDeviceToken: String? { // previous device tokens are not relevant for this class
        willSet {
            guard latestDeviceToken != newValue else { return }
            // Reset state if new token is changed.
            let settings = currentSubscriptions.settings()
            for setting in settings {
                currentSubscriptions.update(setting, toState: .notReported)
            }
        }
        didSet {
            // but we have to save one for PushNotificationDecryptor
            self.deviceTokenSaver.set(newValue: latestDeviceToken)
        }
    }

    init(
        subscriptionSaver: Saver<Set<SubscriptionWithSettings>> = KeychainSaver(key: Key.subscription),
        encryptionKitSaver: Saver<Set<PushSubscriptionSettings>> = PushNotificationDecryptor.saver,
        outdatedSaver: Saver<Set<SubscriptionSettings>> = PushNotificationDecryptor.outdater,
        sessionIDProvider: SessionIdProvider = AuthCredentialSessionIDProvider(),
        // unregister call is unauthorized; register call is authorized one
        // we will inject auth credentials into the call itself
        deviceRegistrator: DeviceRegistrator = PMAPIService.unauthorized,
        signInProvider: SignInProvider = SignInManagerProvider(),
        deviceTokenSaver: Saver<String> = PushNotificationDecryptor.deviceTokenSaver,
        unlockProvider: UnlockProvider = UnlockManagerProvider(),
        notificationCenter: NotificationCenter = NotificationCenter.default,
        lockCacheStatus: LockCacheStatus
    ) {
        self.currentSubscriptions = SubscriptionsPack(subscriptionSaver, encryptionKitSaver, outdatedSaver)
        self.sessionIDProvider = sessionIDProvider
        self.deviceRegistrator = deviceRegistrator
        self.signInProvider = signInProvider
        self.deviceTokenSaver = deviceTokenSaver
        self.unlockProvider = unlockProvider
        self.notificationCenter = notificationCenter
        self.navigationResolver = PushNavigationResolver(
            dependencies: PushNavigationResolver.Dependencies(subscriptionsPack: currentSubscriptions)
        )
        self.notificationActions = PushNotificationActionsHandler(dependencies: .init(lockCacheStatus: lockCacheStatus))

        super.init()

        notificationActions.registerActions()

        notificationCenter.addObserver(
            self,
            selector: #selector(prepareSettingsAndReportAsync),
            name: NSNotification.Name.didUnlock,
            object: nil
        )
    }

    // MARK: - register for notifications
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else {
                SystemLogger.log(message: "User doesn't grant permission", category: .pushNotification)
                return
            }
            DispatchQueue.main.async {
                SystemLogger.log(message: "Register for remote notifications", category: .pushNotification)
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        reportOutdatedSettings()
    }

    func registerIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized:
                self?.registerForRemoteNotifications()
            default:
                break
            }
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: String) {
        let tokenHasChanged = latestDeviceToken != deviceToken
        guard tokenHasChanged else { return }
        SystemLogger.log(message: "Receive new device token", redactedInfo: deviceToken, category: .pushNotification)
        latestDeviceToken = deviceToken
        if signInProvider.isSignedIn, unlockProvider.isUnlocked {
            prepareSettingsAndReportAsync()
        }
    }

    // MARK: - launch options
    func setNotificationFrom(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let notificationKey = UIApplication.LaunchOptionsKey.remoteNotification
        guard
            let launchOption = launchOptions,
            let remoteNotification = launchOption[notificationKey] as? [AnyHashable: Any]
        else {
            return
        }
        notificationOptions = remoteNotification
    }

    func setNotification(
        _ notification: [AnyHashable: Any]?,
        fetchCompletionHandler completionHandler: @escaping () -> Void
    ) {
        notificationOptions = notification
        completionHandler()
    }

    func processCachedLaunchOptions() {
        if let options = notificationOptions {
            try? didReceiveRemoteNotification(options, completionHandler: {})
        }
    }

    func hasCachedNotificationOptions() -> Bool {
        notificationOptions != nil
    }
}

// MARK: - Register / Unregister device token
extension PushNotificationService {
    @objc
    private func prepareSettingsAndReportAsync() {
        unlockQueue.async { [weak self] in
            // cuz encryption kit generation can take significant time
            self?.prepareSettingsAndReport()
        }
    }

    private func prepareSettingsAndReport() {
        guard let deviceToken = latestDeviceToken else { return }

        let sessionIDs = sessionIDProvider.sessionIDs
        if signInProvider.isSignedIn && sessionIDs.isEmpty { return }

        let settingsWeNeedToHave = Set(sessionIDs.map { SubscriptionSettings(token: deviceToken, UID: $0) })

        let outdateSettings = currentSubscriptions.settings().subtracting(settingsWeNeedToHave)
        currentSubscriptions.outdate(outdateSettings)

        let subscriptionsToKeep = currentSubscriptions.subscriptions.filter {
            ($0.state == .reported || $0.state == .pending)
        }

        // Always report all settings to make sure we don't miss any
        let settingsToReport = Set(settingsWeNeedToHave.map { settings -> SubscriptionSettings in
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

        reportSettings(settingsToReport: settingsToReport)

        if let notificationAction = notificationActionPendingUnlock {
            notificationActionPendingUnlock = nil
            handleNotificationActionTask(notificationAction: notificationAction)
        }
    }

    private func generateEncryptionKit(
        for settings: PushNotificationService.SubscriptionSettings
    ) -> SubscriptionSettings {
        var newSettings = settings
        do {
            try newSettings.generateEncryptionKit()
        } catch {
            assertionFailure("failed to generate encryption kit: \(error)")
        }
        return newSettings
    }

    private func reportSettings(settingsToReport: Set<PushNotificationService.SubscriptionSettings>) {
        reportOutdatedSettings()
        let result = report(settingsToReport)

        Self.updateSettingsIfNeeded(
            reportResult: result,
            currentSubscriptions: currentSubscriptions.subscriptions
        ) { [weak self] result in
            self?.currentSubscriptions.update(result.0, toState: result.1)
        }
    }

    // unregister on BE and validate local values
    private func reportOutdatedSettings() {
        currentSubscriptions.outdatedSettings.forEach { setting in
            deviceRegistrator.deviceUnregister(setting) { [weak self] _, result in
                var tokenDeleted = false
                var tokenUnrecognized = false
                switch result {
                case .success:
                    tokenDeleted = true
                case .failure(let error):
                    tokenUnrecognized = (error.code == APIErrorCode.deviceTokenDoesNotExist
                        || error.code == APIErrorCode.deviceTokenIsInvalid)
                }
                if tokenDeleted || tokenUnrecognized {
                    self?.currentSubscriptions.removed(setting)
                }
            }
        }
    }

    // register on BE and validate local values
    private func report(
        _ settingsToReport: Set<SubscriptionSettings>
    ) -> [SubscriptionSettings: SubscriptionState] {
        guard !Thread.isMainThread else {
            assertionFailure("Should not call this method on main thread.")
            return [:]
        }

        var reportResult: [SubscriptionSettings: SubscriptionState] = [:]

        let group = DispatchGroup()
        settingsToReport.forEach { settings in
            group.enter()
            let completion: JSONCompletion = { _, result in
                defer {
                    group.leave()
                }
                switch result {
                case .success:
                    reportResult[settings] = .reported
                case .failure:
                    reportResult[settings] = .notReported
                }
            }
            reportResult[settings] = .pending

            let auth = sharedServices.get(by: UsersManager.self).getUser(by: settings.UID)?.authCredential
            deviceRegistrator.device(registerWith: settings, authCredential: auth, completion: completion)
        }
        group.wait()
        return reportResult
    }

    static func updateSettingsIfNeeded(
        reportResult: [PushNotificationService.SubscriptionSettings: PushNotificationService.SubscriptionState],
        currentSubscriptions: Set<PushNotificationService.SubscriptionWithSettings>,
        updateSubscriptionClosure: (UpdateSubscriptionTuple) -> Void
    ) {
        for result in reportResult {
            // Check if the setting is already reported successfully before.
            // If that's the case, ignore the result to prevent the failing result overriding the successful registration before.
            let currentSubscription = currentSubscriptions.first(where: { $0.settings.UID == result.key.UID })
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

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // App opened tapping on a push notification
            handleRemoteNotification(response: response, completionHandler: completionHandler)
        } else if notificationActions.isKnown(action: response.actionIdentifier) {
            // User tapped on a push notification action
            handleNotificationAction(response: response, completionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let options: UNNotificationPresentationOptions = [.alert, .sound]
        completionHandler(options)
    }
}

// MARK: - Handle remote notification
extension PushNotificationService {
    private func handleRemoteNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if UnlockManager.shared.isUnlocked() { // unlocked
            do {
                try didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
            } catch {
                setNotification(userInfo, fetchCompletionHandler: completionHandler)
            }
        } else if UIApplication.shared.applicationState == .inactive { // opened by push
            setNotification(userInfo, fetchCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }

    private func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping () -> Void
    ) throws {
        guard
            let payload = pushNotificationPayload(userInfo: userInfo),
            shouldHandleNotification(payload: payload)
        else {
            throw PushNotificationServiceError.userIsNotReady
        }
        notificationOptions = nil
        completionHandler()
        navigationResolver.mapNotificationToDeepLink(payload) { [weak self] deeplink in
            self?.notificationCenter.post(name: .switchView, object: deeplink)
        }
    }

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

// MARK: - Handle notification action
extension PushNotificationService {
    private func handleNotificationAction(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let usersManager = sharedServices.get(by: UsersManager.self)
        let userInfo = response.notification.request.content.userInfo
        guard
            let sessionId = userInfo["UID"] as? String,
            let messageId = userInfo["messageId"] as? String
        else {
            SystemLogger.log(message: "Action info parameters not found", category: .pushNotification, isError: true)
            completionHandler()
            return
        }
        let notificationActionPayload = NotificationActionPayload(
            sessionId: sessionId,
            messageId: messageId,
            actionIdentifier: response.actionIdentifier
        )
        let pendingNotificationAction = PendingNotificationAction(
            payload: notificationActionPayload,
            completionHandler: completionHandler
        )
        guard !usersManager.users.isEmpty else {
            // This might mean the app is locked and not able to access
            // authenticated users info yet or that there are no users.
            if usersManager.hasUsers() {
                notificationActionPendingUnlock = pendingNotificationAction
                SystemLogger.log(message: "Action pending \(response.actionIdentifier)", category: .pushNotification)
            } else {
                completionHandler()
            }
            return
        }
        handleNotificationActionTask(notificationAction: pendingNotificationAction)
    }

    private func handleNotificationActionTask(notificationAction action: PendingNotificationAction) {
        let usersManager = sharedServices.get(by: UsersManager.self)
        guard let userId = usersManager.getUser(by: action.payload.sessionId)?.userID else {
            let message = "Action \(action.payload.actionIdentifier): User not found for specific session"
            SystemLogger.log(message: message, category: .pushNotification, isError: true)
            action.completionHandler()
            return
        }
        notificationActions.handle(
            action: action.payload.actionIdentifier,
            userId: userId,
            messageId: action.payload.messageId,
            completion: action.completionHandler
        )
    }
}

private extension PushNotificationService {

    struct PendingNotificationAction {
        let payload: NotificationActionPayload
        let completionHandler: () -> Void
    }

    struct NotificationActionPayload {
        let sessionId: String
        let messageId: String
        let actionIdentifier: String
    }

    enum Key {
        static let subscription = "pushNotificationSubscription"
    }

    enum PushNotificationServiceError: Error {
        case userIsNotReady
    }
}
