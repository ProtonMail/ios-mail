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
import ProtonCoreServices
import UIKit
import UserNotifications

final class PushNotificationService: NSObject {
    /// Pending actions because the app has been just launched and can't make a request yet
    private var deviceTokenRegistrationPendingUnlock: String?
    private var notificationActionPendingUnlock: PendingNotificationAction?
    private var notificationOptions: [AnyHashable: Any]?

    private var debounceTimer: Timer?
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        super.init()

        dependencies.actionsHandler.registerActions()

        let notificationsToObserve: [Notification.Name] = [
            .didSignIn,
            .didUnlock,
            .didSignOutLastAccount
        ]
        notificationsToObserve.forEach {
            dependencies.notificationCenter.addObserver(
                self,
                selector: #selector(didObserveNotification(notification:)),
                name: $0,
                object: nil
            )
        }
    }

    // MARK: - register for notifications
    func authorizeIfNeededAndRegister(completion: (() -> Void)? = nil) {
        guard !ProcessInfo.isRunningUITests else {
            SystemLogger.log(message: "push registration disabled for UI tests ", category: .pushNotification)
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {

                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    SystemLogger.log(message: "user has disabled push notifications", category: .pushNotification)
                }

                completion?()
            }
        }
    }

    func registerIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized:
                self?.authorizeIfNeededAndRegister()
            default:
                break
            }
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: String) {
        guard dependencies.usersManager.hasUsers(), dependencies.unlockProvider.isUnlocked() else {
            deviceTokenRegistrationPendingUnlock = deviceToken
            return
        }
        // we avoid calling the device registration flow in a quick sequence with a delay
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.dependencies.pushEncryptionManager.registerDeviceForNotifications(deviceToken: deviceToken)
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

    func resumePendingTasks() {
        if let deviceToken = deviceTokenRegistrationPendingUnlock {
            deviceTokenRegistrationPendingUnlock = nil
            dependencies.pushEncryptionManager.registerDeviceForNotifications(deviceToken: deviceToken)
        }

        if let notificationAction = notificationActionPendingUnlock {
            notificationActionPendingUnlock = nil
            handleNotificationActionTask(notificationAction: notificationAction)
        }

        if let options = notificationOptions {
            try? didReceiveRemoteNotification(options, completionHandler: {})
        }
    }
}

// MARK: - NotificationCenter observation

extension PushNotificationService {

    @objc
    private func didObserveNotification(notification: Notification) {
        switch notification.name {
        case .didSignIn:
            didSignInAccount()
        case .didUnlock:
            didUnlockApp()
        case .didSignOutLastAccount:
            didSignOutLastAccount()
        default:
            PMAssertionFailure("\(notification.name) not expected")
        }
    }

    private func didUnlockApp() {
        resumePendingTasks()
    }

    private func didSignInAccount() {
        dependencies.pushEncryptionManager.registerDeviceAfterNewAccountSignIn()
    }

    private func didSignOutLastAccount() {
        dependencies.pushEncryptionManager.deleteAllCachedData()
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
        } else if dependencies.actionsHandler.isKnown(action: response.actionIdentifier) {
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
        let options: UNNotificationPresentationOptions = [.list, .banner, .sound]
        completionHandler(options)
    }
}

// MARK: - Handle remote notification
extension PushNotificationService {
    private func handleRemoteNotification(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if dependencies.unlockProvider.isUnlocked() { // unlocked
            do {
                SystemLogger.log(
                    message: "HandleRemoteNotification: device isUnlocked, id: \(userInfo["messageId"] as? String ?? "No msgId found")",
                    category: .notificationDebug
                )
                try didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
            } catch {
                SystemLogger.log(
                    message: "HandleRemoteNotification: device isUnlocked, but has error \(error.localizedDescription), id: \(userInfo["messageId"] as? String ?? "No msgId found")",
                    category: .notificationDebug
                )
                setNotification(userInfo, fetchCompletionHandler: completionHandler)
            }
        } else if UIApplication.shared.applicationState == .inactive { // opened by push
            SystemLogger.log(
                message: "HandleRemoteNotification: device locked, id: \(userInfo["messageId"] as? String ?? "No msgId found")",
                category: .notificationDebug
            )
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
        SystemLogger.log(
            message: "DidReceiveRemoteNotification: start mapNotificationToDeepLink, id: \(userInfo["messageId"] as? String ?? "No msgId found")",
            category: .notificationDebug
        )
        dependencies.navigationResolver.mapNotificationToDeepLink(payload) { [weak self] deeplink in
            SystemLogger.log(
                message: "DidReceiveRemoteNotification: post notification to switch view, id: \(userInfo["messageId"] as? String ?? "No msgId found")",
                category: .notificationDebug
            )
            self?.dependencies.notificationCenter.post(name: .switchView, object: deeplink)
        }
    }

    private func pushNotificationPayload(userInfo: [AnyHashable: Any]) -> PushNotificationPayload? {
        do {
            return try PushNotificationPayload(userInfo: userInfo)
        } catch {
            let message = "Fail parsing push payload. Error: \(String(describing: error))"
            SystemLogger.log(message: message, category: .pushNotification, isError: true)
            return nil
        }
    }

    private func shouldHandleNotification(payload: PushNotificationPayload) -> Bool {
        guard dependencies.usersManager.hasUsers() && dependencies.unlockProvider.isUnlocked() else {
            return false
        }
        return payload.isLocalNotification || (!payload.isLocalNotification && isUserManagerReady(payload: payload))
    }

    /// Given how the application logic sets up some services at launch time, when a push notification awakes the app, UserManager might
    /// not be set up yet, even with an authenticated user. This function is a patch to be sure UserManager is ready when the app has been
    /// launched by a remote notification being tapped by the user.
    private func isUserManagerReady(payload: PushNotificationPayload) -> Bool {
        guard let uid = payload.uid else { return false }
        return dependencies.usersManager.getUser(by: uid) != nil
    }
}

// MARK: - Handle notification action

extension PushNotificationService {
    private func handleNotificationAction(response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        let usersManager = dependencies.usersManager
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
        let usersManager = dependencies.usersManager
        guard let userId = usersManager.getUser(by: action.payload.sessionId)?.userID else {
            let message = "Action \(action.payload.actionIdentifier): User not found for specific session"
            SystemLogger.log(message: message, category: .pushNotification, isError: true)
            action.completionHandler()
            return
        }
        let completion = {
            DispatchQueue.main.async {
                action.completionHandler()
            }
        }
        dependencies.actionsHandler.handle(
            action: action.payload.actionIdentifier,
            userId: userId,
            messageId: action.payload.messageId,
            completion: completion
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

    enum PushNotificationServiceError: Error {
        case userIsNotReady
    }
}

extension PushNotificationService {
    struct Dependencies {
        let actionsHandler: PushNotificationActionsHandler
        let usersManager: UsersManagerProtocol
        let unlockProvider: UnlockProvider
        let pushEncryptionManager: PushEncryptionManagerProtocol
        let navigationResolver: PushNavigationResolver
        let notificationCenter: NotificationCenter

        init(
            actionsHandler: PushNotificationActionsHandler,
            usersManager: UsersManagerProtocol,
            unlockProvider: UnlockProvider,
            pushEncryptionManager: PushEncryptionManagerProtocol,
            navigationResolver: PushNavigationResolver = PushNavigationResolver(dependencies: .init()),
            notificationCenter: NotificationCenter = NotificationCenter.default
        ) {
            self.actionsHandler = actionsHandler
            self.usersManager = usersManager
            self.unlockProvider = unlockProvider
            self.pushEncryptionManager = pushEncryptionManager
            self.navigationResolver = navigationResolver
            self.notificationCenter = notificationCenter
        }
    }
}
