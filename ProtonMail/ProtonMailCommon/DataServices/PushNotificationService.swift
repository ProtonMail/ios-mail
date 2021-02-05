//
//  PushNotificationService.swift
//  ProtonMail
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
import UIKit
import SWRevealViewController
import PMKeymaker
import UserNotifications
import PMCommon

public class PushNotificationService: NSObject, Service {

    typealias SubscriptionSettings = PushSubscriptionSettings
    
    enum Key {
        static let subscription = "pushNotificationSubscription"
    }
    
    fileprivate var launchOptions: [AnyHashable: Any]? = nil

    
    /// message service
    private let messageService: MessageDataService?
    
    ///
    private let sessionIDProvider: SessionIdProvider
    private let deviceRegistrator: DeviceRegistrator
    private let signInProvider: SignInProvider
    private let unlockProvider: UnlockProvider
    private let deviceTokenSaver: Saver<String>
    
    private let unlockQueue = DispatchQueue(label: "PushNotificationService.unlock")
    
    init(service: MessageDataService? = nil,
         subscriptionSaver: Saver<Set<SubscriptionWithSettings>> = KeychainSaver(key: Key.subscription),
         encryptionKitSaver: Saver<Set<PushSubscriptionSettings>> = PushNotificationDecryptor.saver,
         outdatedSaver: Saver<Set<SubscriptionSettings>> = PushNotificationDecryptor.outdater,
         sessionIDProvider: SessionIdProvider = AuthCredentialSessionIDProvider(),
         deviceRegistrator: DeviceRegistrator = PMAPIService.unauthorized, // unregister call is unauthorized; register call is authorized one, we will inject auth credentials into the call itself
         signInProvider: SignInProvider = SignInManagerProvider(),
         deviceTokenSaver: Saver<String> = PushNotificationDecryptor.deviceTokenSaver,
         unlockProvider: UnlockProvider = UnlockManagerProvider())
    {
        self.messageService = service
        self.currentSubscriptions = SubscriptionsPack(subscriptionSaver, encryptionKitSaver, outdatedSaver)
        self.sessionIDProvider = sessionIDProvider
        self.deviceRegistrator = deviceRegistrator
        self.signInProvider = signInProvider
        self.deviceTokenSaver = deviceTokenSaver
        self.unlockProvider = unlockProvider
        self.latestDeviceToken = KeychainWrapper.keychain.string(forKey: PushNotificationDecryptor.Key.deviceToken)
        super.init()
        
        defer {
            NotificationCenter.default.addObserver(self, selector: #selector(didUnlockAsync), name: NSNotification.Name.didUnlock, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didSignOut), name: NSNotification.Name.didSignOut, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    public func registerForRemoteNotifications() {
        ///TODO::fixme we don't need to request this remote when start until logged in. we only need to register after user logged in
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        self.unreportOutdated()
    }
    
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: String) {
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
    
    private func didUnlock() {
        guard case let sessionIDs = self.sessionIDProvider.sessionIDs, let deviceToken = self.latestDeviceToken else {
            return
        }
        
        let settingsWeNeedToHave = sessionIDs.map { SubscriptionSettings(token: deviceToken, UID: $0) }
        
        let settingsToUnreport = self.currentSubscriptions.settings().subtracting(Set(settingsWeNeedToHave))
        self.currentSubscriptions.outdate(settingsToUnreport)
        
        let subscriptionsToKeep = self.currentSubscriptions.subscriptions.filter { $0.state == .reported && !settingsToUnreport.contains($0.settings) }
        var settingsToReport = Set(settingsWeNeedToHave).subtracting(Set(subscriptionsToKeep.map { $0.settings}))
        settingsToReport = Set(settingsToReport.map { settings -> SubscriptionSettings in
            var newSettings = settings
            do {
                try newSettings.generateEncryptionKit()
            } catch let error {
                assert(false, "failed to generate enryption kit: \(error)")
            }
            return newSettings
        })
        
        let subcriptionsBeforeReport = Set(settingsToReport.map { SubscriptionWithSettings(settings: $0, state: .notReported) })
        self.currentSubscriptions.insert(subcriptionsBeforeReport)
        self.report(settingsToReport)
        self.unreportOutdated()
    }
    
    @objc private func didSignOut() {
        let settingsToUnreport = self.currentSubscriptions.subscriptions.compactMap { subscription -> SubscriptionSettings? in
            return subscription.state == .notReported ? nil : subscription.settings
        }
        self.currentSubscriptions.outdate(Set(settingsToUnreport))
        self.unreportOutdated()
    }
    
    // register on BE and validate local values
    private func report(_ settingsToReport: Set<SubscriptionSettings>) {
        settingsToReport.forEach { settings in
            let completion: CompletionBlock = { _, _, error in
                guard error == nil else {
                    self.currentSubscriptions.update(settings, toState: .notReported)
                    return
                }
                self.currentSubscriptions.update(settings, toState: .reported)
            }
            self.currentSubscriptions.update(settings, toState: .pending)
            
            let auth = sharedServices.get(by: UsersManager.self).getUser(bySessionID: settings.UID)?.auth
            self.deviceRegistrator.device(registerWith: settings, authCredential: auth, completion: completion)
        }
    }
    
    // unregister on BE and validate local values
    internal func unreportOutdated() {
        self.currentSubscriptions.outdatedSettings.forEach { settings in
            let completion: CompletionBlock = { _, _, error in
                guard error == nil ||               // no errors
                    error?.code == 11211 ||         // "Device does not exist"
                    error?.code == 11200 else       // "Invalid device token"
                {
                    return
                }
                self.currentSubscriptions.removed(settings)
            }
            self.deviceRegistrator.deviceUnregister(settings, completion: completion)
        }
    }
    
    // MARK: - launch options
    
    public func setLaunchOptions (_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let launchoption = launchOptions {
            if let remoteNotification = launchoption[UIApplication.LaunchOptionsKey.remoteNotification ] as? [AnyHashable: Any] {
                self.launchOptions = remoteNotification
            }
        }
    }
    
    public func setNotificationOptions (_ userInfo: [AnyHashable: Any]?, fetchCompletionHandler completionHandler: @escaping () -> Void) {
        self.launchOptions = userInfo
        completionHandler()
    }
    
    public func processCachedLaunchOptions() {
        if let options = self.launchOptions {
            self.didReceiveRemoteNotification(options, forceProcess: true, fetchCompletionHandler: { })
        }
    }
    
    func hasCachedLaunchOptions() -> Bool {
        return self.launchOptions != nil
    }
    
    // MARK: - notifications
    
    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any],
                                             forceProcess : Bool = false, fetchCompletionHandler completionHandler: @escaping () -> Void) {
        guard sharedServices.get(by: UsersManager.self).hasUsers(), UnlockManager.shared.isUnlocked() else {
            completionHandler()
            return
        }
        
        guard let messageid = messageIDForUserInfo(userInfo), let uidFromPush = userInfo["UID"] as? String,
            let user = sharedServices.get(by: UsersManager.self).getUser(bySessionID: uidFromPush) else
        {
            completionHandler()
            return
        }
        
        self.launchOptions = nil

        user.messageService.fetchNotificationMessageDetail(messageid) { (task, response, message, error) -> Void in
            guard error == nil else {
                completionHandler()
                return
            }

            switch userInfo["category"] as? String {
            case .some(LocalNotificationService.Categories.failedToSend.rawValue):
                let link = DeepLink(MenuCoordinatorNew.Setup.switchUserFromNotification.rawValue, sender: uidFromPush)
                link.append(.init(name: MenuCoordinatorNew.Destination.mailbox.rawValue, value: Message.Location.draft.rawValue))
                NotificationCenter.default.post(name: .switchView, object: link)
            default:
                user.messageService.pushNotificationMessageID = messageid
                let link = DeepLink(MenuCoordinatorNew.Setup.switchUserFromNotification.rawValue, sender: uidFromPush)
                link.append(.init(name: MenuCoordinatorNew.Destination.mailbox.rawValue))
                link.append(.init(name: MailboxCoordinator.Destination.detailsFromNotify.rawValue))
                NotificationCenter.default.post(name: .switchView, object: link)
            }
            completionHandler()
        }
    }
    
    // MARK: - Private methods
    private func messageIDForUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        if let encrypted = userInfo["encryptedMessage"] as? String,
            let uid = userInfo["UID"] as? String { // new pushes
            guard let encryptionKit = self.currentSubscriptions.encryptionKit(forUID: uid) else {
                assert(false, "no encryption kit fround")
                return nil
            }
            do {
                guard let plaintext = try encrypted.decryptMessageWithSinglKey(encryptionKit.privateKey, passphrase: encryptionKit.passphrase) else {
                    return nil
                }
                guard let push = PushData.parse(with: plaintext) else {
                    return nil
                }
                return push.messageId
            } catch let error {
                PMLog.D("Error while opening message via push: \(error)")
                return nil
            }
        } else if let messageArray = userInfo["message_id"] as? NSArray { // old pushes
            return messageArray.firstObject as? String
        } else { // local notifications
            return userInfo["message_id"] as? String
        }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let userInfo = response.notification.request.content.userInfo
        if UnlockManager.shared.isUnlocked() { // unlocked
            self.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        } else if UIApplication.shared.applicationState == .inactive { // opened by push
            self.setNotificationOptions(userInfo, fetchCompletionHandler: completionHandler)
        } else {
            // app is locked and not opened from push - nothing to do here
            completionHandler()
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let options: UNNotificationPresentationOptions = [.alert, .sound]   
        completionHandler(options)
    }
}

// MARK: - Dependency Injection sugar

protocol SessionIdProvider {
    var sessionIDs: Array<String> { get }
}

struct AuthCredentialSessionIDProvider: SessionIdProvider {
    var sessionIDs: Array<String> {
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

