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
import Keymaker
import UserNotifications

public class PushNotificationService: NSObject, Service {

    typealias SubscriptionSettings = PushSubscriptionSettings
    
    enum Key {
        static let subscription = "pushNotificationSubscription"
    }
    
    fileprivate var launchOptions: [AnyHashable: Any]? = nil

    
    /// message service
    private let messageService: MessageDataService?
    
    ///
    private let subscriptionSaver: Saver<Set<Subscription>>
    private let outdatedSaver: Saver<Set<SubscriptionSettings>>
    private let encryptionKitSaver: Saver<Set<SubscriptionSettings>>
    private let sessionIDProvider: SessionIdProvider
    private let deviceRegistrator: DeviceRegistrator
    private let signInProvider: SignInProvider
    private let unlockProvider: UnlockProvider
    private let deviceTokenSaver: Saver<String>
    
    init(service: MessageDataService? = nil,
         subscriptionSaver: Saver<Set<Subscription>> = KeychainSaver(key: Key.subscription),
         encryptionKitSaver: Saver<Set<PushSubscriptionSettings>> = PushNotificationDecryptor.saver,
         outdatedSaver: Saver<Set<SubscriptionSettings>> = PushNotificationDecryptor.outdater,
         sessionIDProvider: SessionIdProvider = AuthCredentialSessionIDProvider(),
         deviceRegistrator: DeviceRegistrator = APIService.shared, //TODO:: fix me
         signInProvider: SignInProvider = SignInManagerProvider(),
         deviceTokenSaver: Saver<String> = PushNotificationDecryptor.deviceTokenSaver,
         unlockProvider: UnlockProvider = UnlockManagerProvider())
    {
        self.messageService = service
        self.subscriptionSaver = subscriptionSaver
        self.encryptionKitSaver = encryptionKitSaver
        self.outdatedSaver = outdatedSaver
        self.sessionIDProvider = sessionIDProvider
        self.deviceRegistrator = deviceRegistrator
        self.signInProvider = signInProvider
        self.deviceTokenSaver = deviceTokenSaver
        self.unlockProvider = unlockProvider
        
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
        didSet { self.deviceTokenSaver.set(newValue: latestDeviceToken)} // but we have to save one for PushNotificationDecryptor
    }
    fileprivate var outdatedSettings: Set<SubscriptionSettings> {
        get { return self.outdatedSaver.get() ?? [] } // cuz PushNotificationDecryptor can add values to this colletion while app is running
        set { self.outdatedSaver.set(newValue: newValue) } // in keychain cuz should persist over reinstalls
    }
    fileprivate var currentSubscriptions: Set<Subscription> {
        get { return self.subscriptionSaver.get() ?? Set([Subscription.none]) }
        set {
            self.subscriptionSaver.set(newValue: newValue) // in keychain cuz should persist over reinstalls
            
            let reportedSettings: [SubscriptionSettings] = newValue.compactMap { subscription -> SubscriptionSettings? in
                switch subscription { // save encryption kit to userdefaults for PushNotificationDecryptor but not persist over reinstalls
                case .reported(let settings):   return settings
                default:                        return nil
                }
            }
            
            self.encryptionKitSaver.set(newValue: Set(reportedSettings))
        }
    }
    
    // MARK: - register for notificaitons
    
    public func registerForRemoteNotifications() {
        ///TODO::fixme we don't need to request this remote when start until logged in. we only need to register after user logged in
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        self.unreport(self.outdatedSettings)
    }
    
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: String) {
        self.latestDeviceToken = deviceToken
        if self.signInProvider.isSignedIn, self.unlockProvider.isUnlocked {
            self.didUnlockAsync()
        }
    }
    
    @objc private func didUnlockAsync() {
        DispatchQueue.global().async {
            self.didUnlock()    // cuz encryption kit generation can take significant time
        }
    }
    
    private func didUnlock() {
        guard case let sessionIDs = self.sessionIDProvider.sessionIDs, let deviceToken = self.latestDeviceToken else {
            return
        }
        
        let settingsWeNeedToHave = sessionIDs.map { SubscriptionSettings(token: deviceToken, UID: $0) }
        
        var settingsToUnreport = Array<SubscriptionSettings>()
        var settingsAlreadyReported = Array<SubscriptionSettings>()
        var subscriptionsToKeep = Array<Subscription>()
        
        self.currentSubscriptions.forEach { subscription in
            switch subscription {
            case .notReported(let oldSettings) where !settingsWeNeedToHave.contains(oldSettings),
                 .pending(let oldSettings) where !settingsWeNeedToHave.contains(oldSettings),
                 .reported(let oldSettings) where !settingsWeNeedToHave.contains(oldSettings):
                
                settingsToUnreport.append(oldSettings)
                
            case .reported(let relevantSettings), .pending(let relevantSettings), .notReported(let relevantSettings):
                
                subscriptionsToKeep.append(subscription)
                settingsAlreadyReported.append(relevantSettings)
                
            default: break
            }
        }
        
        let settingsToReport = settingsWeNeedToHave.filter { !settingsToUnreport.contains($0) && !settingsAlreadyReported.contains($0) }
        let settingsToReportWithEncryptionKit = settingsToReport.map { settings -> SubscriptionSettings in
            var newSettings = settings
            do {
                try newSettings.generateEncryptionKit()
            } catch let error {
                assert(false, "failed to generate enryption kit: \(error)")
            }
            return newSettings
        }
        
        self.currentSubscriptions = Set(subscriptionsToKeep)
        self.report(Set(settingsToReportWithEncryptionKit))
    }
    
    @objc private func didSignOut() {
        let settingsToUnreport = self.currentSubscriptions.compactMap { subscription -> SubscriptionSettings? in
            switch subscription {
            case .reported(let currentSettings), .pending(let currentSettings):
                return currentSettings
            case .none, .notReported:
                return nil
            }
        }
        self.unreport(Set(settingsToUnreport))
    }
    
    // register on BE and validate local values
    private func report(_ settingsToReport: Set<SubscriptionSettings>) {
        let subscriptionsToKeep = self.currentSubscriptions.filter { subscription in
            switch subscription {
            case .reported(let currentSettings), .pending(let currentSettings):
                return !settingsToReport.contains(currentSettings)
            case .none, .notReported:
                return false
            }
        }
        
        let pending = Set(settingsToReport.map(Subscription.pending))
        self.currentSubscriptions = pending.union(Set(subscriptionsToKeep))
        
        settingsToReport.forEach { settings in
            let completion: CompletionBlock = { _, _, error in
                self.currentSubscriptions.remove(.pending(settings))
                guard error == nil else {
                    self.currentSubscriptions.insert(.notReported(settings))
                    return
                }
                self.currentSubscriptions.insert(.reported(settings))
                self.outdatedSettings.remove(settings)
            }
            if let auth = sharedServices.get(by: UsersManager.self).getUser(bySessionID: settings.UID)?.auth {
                self.deviceRegistrator.device(registerWith: settings, authCredential: auth, completion: completion)
            } else {
                self.outdatedSettings.insert(settings)
            }
        }
        self.unreport(self.outdatedSettings)
    }
    
    // unregister on BE and validate local values
    internal func unreport(_ settingsToUnreport: Set<SubscriptionSettings>) {
        settingsToUnreport.forEach { settings in
            let completion: CompletionBlock = { _, _, error in
                guard error == nil ||               // no errors
                    error?.code == 11211 ||         // "Device does not exist"
                    error?.code == 11200 else       // "Invalid device token"
                {
                    self.outdatedSettings.insert(settings)
                    return
                }
                self.outdatedSettings.remove(settings)
                
                // just in case
                self.currentSubscriptions.remove(.reported(settings))
                self.currentSubscriptions.remove(.notReported(settings))
                self.currentSubscriptions.remove(.pending(settings))
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
    
    // MARK: - notifications
    
    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any],
                                             forceProcess : Bool = false, fetchCompletionHandler completionHandler: @escaping () -> Void) {
        //TODO:: fix me
        //        guard SignInManager.shared.isSignedIn(), UnlockManager.shared.isUnlocked() else { // FIXME: test locked flow
//            completionHandler()
//            return
//        }
        
        let application = UIApplication.shared
        guard let messageid = messageIDForUserInfo(userInfo) else {
            completionHandler()
            return
        }
        
        // if the app is in the background, then switch to the inbox and load the message detail
        guard application.applicationState == UIApplication.State.inactive || application.applicationState == UIApplication.State.background || forceProcess else {
            completionHandler()
            return
        }
        
        self.launchOptions = nil
        
        //TODO:: fix me -- look up by userid and message id
//        messageService.fetchNotificationMessageDetail(messageid) { (task, response, message, error) -> Void in
//            guard error == nil else {
//                completionHandler()
//                return
//            }
//
//
//            switch userInfo["category"] as? String {
//            case .some(LocalNotificationService.Categories.failedToSend.rawValue):
//                let link = DeepLink.init(MenuCoordinatorNew.Destination.mailbox.rawValue, sender: Message.Location.draft.rawValue)
//                NotificationCenter.default.post(name: .switchView, object: link)
//            default:
//                self.messageService.pushNotificationMessageID = messageid
//                let link = DeepLink(MenuCoordinatorNew.Destination.mailbox.rawValue)
//                link.append(.init(name: MailboxCoordinator.Destination.detailsFromNotify.rawValue))
//                NotificationCenter.default.post(name: .switchView, object: link)
//            }
//            completionHandler()
//        }
    }
    
    // MARK: - Private methods
    private func messageIDForUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        if let encrypted = userInfo["encryptedMessage"] as? String { // new pushes
            guard let encryptionKit = self.encryptionKitSaver.get()?.first(where: { $0.UID == "FIXME" })?.encryptionKit else {
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
        //TODO:: fix me
//        let userInfo = response.notification.request.content.userInfo
//        if UnlockManager.shared.isUnlocked() { // unlocked
//            self.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
//        } else if UIApplication.shared.applicationState == .inactive { // opened by push
//            self.setNotificationOptions(userInfo, fetchCompletionHandler: completionHandler)
//        } else {
//            // app is locked and not opened from push - nothing to do here
//            completionHandler()
//        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        let userInfo = notification.request.content.userInfo
        let options: UNNotificationPresentationOptions = [.alert, .sound]
        
        //TODO:: fix me
//        if UnlockManager.shared.isUnlocked() { // foreground
//            self.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: { completionHandler(options) } )
//        } else {
//            completionHandler(options)
//        }
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
        return SignInManager.shared.isSignedIn()
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
    func device(registerWith settings: PushSubscriptionSettings, authCredential: AuthCredential, completion: CompletionBlock?)
    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping CompletionBlock)
}

extension APIService: DeviceRegistrator {}

