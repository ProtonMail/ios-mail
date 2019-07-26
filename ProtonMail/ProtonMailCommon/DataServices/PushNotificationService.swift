//
//  PushNotificationService.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import UIKit
import SWRevealViewController
import Keymaker

public class PushNotificationService: Service {

    typealias SubscriptionSettings = PushSubscriptionSettings
    
    enum Key {
        static let subscription = "pushNotificationSubscription"
    }
    
    fileprivate var launchOptions: [AnyHashable: Any]? = nil

    
    /// message service
    private let messageService: MessageDataService
    
    ///
    private let subscriptionSaver: Saver<Subscription>
    private let outdatedSaver: Saver<Set<SubscriptionSettings>>
    private let encryptionKitSaver: Saver<SubscriptionSettings>
    private let sessionIDProvider: SessionIdProvider
    private let deviceRegistrator: DeviceRegistrator
    private let signInProvider: SignInProvider
    private let unlockProvider: UnlockProvider
    private let deviceTokenSaver: Saver<String>
    
    init(service: MessageDataService,
         subscriptionSaver: Saver<Subscription> = KeychainSaver(key: Key.subscription),
         encryptionKitSaver: Saver<PushSubscriptionSettings> = PushNotificationDecryptor.saver,
         outdatedSaver: Saver<Set<SubscriptionSettings>> = PushNotificationDecryptor.outdater,
         sessionIDProvider: SessionIdProvider = AuthCredentialSessionIDProvider(),
         deviceRegistrator: DeviceRegistrator = sharedAPIService,
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
    fileprivate var currentSubscription: Subscription {
        get { return self.subscriptionSaver.get() ?? .none }
        set {
            self.subscriptionSaver.set(newValue: newValue) // in keychain cuz should persist over reinstalls
            
            switch newValue { // save encryption kit to userdefaults for PushNotificationDecryptor but not persist over reinstalls
            case .reported(let settings):   self.encryptionKitSaver.set(newValue: settings)
            default:                        self.encryptionKitSaver.set(newValue: nil)
            }
        }
    }
    
    // MARK: - register for notificaitons
    
    public func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            let types: UIUserNotificationType = [.badge , .sound , .alert]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        self.outdatedSettings.forEach(self.unreport)
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
        guard let sessionID = self.sessionIDProvider.sessionID, let deviceToken = self.latestDeviceToken else {
            return
        }
        
        let newSettings = SubscriptionSettings(token: deviceToken, UID: sessionID)
        
        switch self.currentSubscription {
        case .none, .notReported:
            self.currentSubscription = .notReported(newSettings)
            
        case .pending(let oldSettings) where oldSettings != newSettings:
            self.outdatedSettings.insert(oldSettings)
            self.currentSubscription = .notReported(newSettings)
            
        case .reported(let oldSettings) where oldSettings != newSettings:
            self.outdatedSettings.insert(oldSettings)
            self.currentSubscription = .notReported(newSettings)
            
        default: break
        }
        
        guard case Subscription.notReported(var newSettingsWithEncryptionKit) = self.currentSubscription else {
            return // cuz nothing needs to be repoorted
        }
        
        guard let _ = try? newSettingsWithEncryptionKit.generateEncryptionKit() else {
            assert(false, "failed to generate enryption kit") // will crash only on debug builds
            return // cuz no sence in subscribing without privateKey
        }
        
        self.currentSubscription = .notReported(newSettingsWithEncryptionKit)
        self.report(newSettingsWithEncryptionKit)
    }
    
    @objc private func didSignOut() {
        switch self.currentSubscription {
        case .reported(let currentSettings), .pending(let currentSettings):
            self.unreport(currentSettings)
            
        case .none, .notReported:
            break
        }
    }
    
    // register on BE and validate local values
    private func report(_ settings: SubscriptionSettings) {
        self.currentSubscription = .pending(settings)
        let completion: APIService.CompletionBlock = { _, _, error in
            guard error == nil else {
                self.currentSubscription = .notReported(settings)
                return
            }
            self.currentSubscription = .reported(settings)
            self.outdatedSettings.remove(settings)
            self.outdatedSettings.forEach(self.unreport)
        }
        
        self.deviceRegistrator.device(registerWith: settings, completion: completion)
    }
    
    // unregister on BE and validate local values
    internal func unreport(_ settings: SubscriptionSettings) {
        let completion: APIService.CompletionBlock = { _, _, error in
            guard error == nil ||               // no errors
                error?.code == 11211 ||         // "Device does not exist"
                error?.code == 11200 else       // "Invalid device token"
            {
                self.outdatedSettings.insert(settings)
                return
            }
            self.outdatedSettings.remove(settings)
            
            switch self.currentSubscription {
            case .none: break
            case .reported(let currentSettings), .pending(let currentSettings), .notReported(let currentSettings):
                if settings == currentSettings {
                    self.currentSubscription = .none
                }
            }
        }
        
        self.deviceRegistrator.deviceUnregister(settings, completion: completion)
    }
    
    // MARK: - launch options
    
    public func setLaunchOptions (_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let launchoption = launchOptions {
            if let remoteNotification = launchoption[UIApplication.LaunchOptionsKey.remoteNotification ] as? [AnyHashable: Any] {
                self.launchOptions = remoteNotification
            }
        }
    }
    
    // needed to be called from WindowSceneDelegate to prevent merge conflict with other branch, can be removed in August 2019
    public func setNotificationOptions(_ userInfo: [AnyHashable: Any]?) {
        self.launchOptions = userInfo
    }
    
    public func setNotificationOptions (_ userInfo: [AnyHashable: Any]?, fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.launchOptions = userInfo
        completionHandler(.noData)
    }
    
    public func processCachedLaunchOptions() {
        if let options = self.launchOptions {
            self.didReceiveRemoteNotification(options, forceProcess: true, fetchCompletionHandler: { (UIBackgroundFetchResult) -> Void in
            })
        }
    }
    
    // MARK: - notifications
    
    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], forceProcess : Bool = false, fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard SignInManager.shared.isSignedIn(), UnlockManager.shared.isUnlocked() else { // FIXME: test locked flow
            completionHandler(.failed)
            return
        }
        
        let application = UIApplication.shared
        guard let messageid = messageIDForUserInfo(userInfo) else {
            completionHandler(.failed)
            return
        }
        
        // if the app is in the background, then switch to the inbox and load the message detail
        guard application.applicationState == UIApplication.State.inactive || application.applicationState == UIApplication.State.background || forceProcess else {
            completionHandler(.failed)
            return
        }
        
        self.launchOptions = nil
        messageService.fetchNotificationMessageDetail(messageid) { (task, response, message, error) -> Void in
            guard error == nil else {
                completionHandler(.failed)
                return
            }
            let link = DeepLink(MenuCoordinatorNew.Destination.mailbox.rawValue)
            link.append(.init(name: MailboxCoordinator.Destination.detailsFromNotify.rawValue))
            self.messageService.pushNotificationMessageID = messageid
            NotificationCenter.default.post(name: .switchView,
                                            object: link)
            completionHandler(.newData)
        }
    }
    
    // MARK: - Private methods
    private func messageIDForUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        if let encrypted = userInfo["encryptedMessage"] as? String {
            guard let encryptionKit = self.encryptionKitSaver.get()?.encryptionKit else {
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
        } else {
            guard let messageArray = userInfo["message_id"] as? NSArray else {
                return nil
            }
            return messageArray.firstObject as? String
        }
    }
}

// MARK: - Dependency Injection sugar

protocol SessionIdProvider {
    var sessionID: String? { get }
}

struct AuthCredentialSessionIDProvider: SessionIdProvider {
    var sessionID: String? {
        return AuthCredential.fetchFromKeychain()?.userID
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
        return UnlockManager.shared.isUnlocked()
    }
}

protocol DeviceRegistrator {
    func device(registerWith settings: PushSubscriptionSettings, completion: APIService.CompletionBlock?)
    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping APIService.CompletionBlock)
}

extension APIService: DeviceRegistrator {}
