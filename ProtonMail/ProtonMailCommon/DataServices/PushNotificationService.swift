//
//  PushNotificationService.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import UIKit
import SWRevealViewController
import Keymaker

public class PushNotificationService {
    public static var shared = PushNotificationService()
    private static let keychainKey = String(describing: PushNotificationService.self)
    fileprivate var newerDeviceToken: String?
    fileprivate var launchOptions: [AnyHashable: Any]? = nil
    
    // these two should be in Keychain in order to unregister after reinstall
    fileprivate var outdatedSettings: Set<APIService.PushSubscriptionSettings> = []
    fileprivate var currentSubscription: Subscription {
        get {
            guard let raw = sharedKeychain.keychain.data(forKey: PushNotificationService.keychainKey),
                let subscription = try? PropertyListDecoder().decode(PushNotificationService.Subscription.self, from: raw) else
            {
                return .none
            }
            return subscription
        }
        set {
            // save subscription to keychain
            guard let raw = try? PropertyListEncoder().encode(newValue) else {
                sharedKeychain.keychain.removeItem(forKey: PushNotificationService.keychainKey)
                return
            }
            sharedKeychain.keychain.setData(raw, forKey: PushNotificationService.keychainKey)
            
            // save encryption kit to userdefaults
            if case Subscription.reported(let settings) = newValue {
                PushNotificationDecryptor.encryptionKit = settings.encryptionKit
            } else {
                PushNotificationDecryptor.encryptionKit = nil
            }
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUnlock), name: NSNotification.Name.didUnlock, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didSignOut), name: NSNotification.Name.didSignOut, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        self.newerDeviceToken = deviceToken
        if SignInManager.shared.isSignedIn(), let _ = keymaker.mainKey {
            self.didUnlock()
        }
    }
    
    @objc private func didUnlock() {
        guard let sessionID = AuthCredential.fetchFromKeychain()?.userID,
            let deviceToken = self.newerDeviceToken else
        {
            return
        }
        
        let newSettings = APIService.PushSubscriptionSettings(token: deviceToken, UID: sessionID) // here new keypair will be created
        
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
        
        guard case Subscription.notReported(let currentSettings) = self.currentSubscription else {
            return
        }
        
        self.report(currentSettings)
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
    private func report(_ settings: APIService.PushSubscriptionSettings) {
        self.currentSubscription = .pending(settings)
        sharedAPIService.device(registerWith: settings) { _, _, error in
            guard error == nil else {
                self.currentSubscription = .notReported(settings)
                return
            }
            self.currentSubscription = .reported(settings)
            self.outdatedSettings.remove(settings)
        }
    }
    
    // unregister on BE and validate local values
    internal func unreport(_ settings: APIService.PushSubscriptionSettings) {
        sharedAPIService.deviceUnregister(settings) { _, _, error in
            guard error == nil else {
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
    }
    
    // MARK: - launch options
    
    public func setLaunchOptions (_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let launchoption = launchOptions {
            if let remoteNotification = launchoption[UIApplication.LaunchOptionsKey.remoteNotification ] as? [AnyHashable: Any] {
                self.launchOptions = remoteNotification
            }
        }
    }
    
    public func setNotificationOptions (_ userInfo: [AnyHashable: Any]?) {
        self.launchOptions = userInfo
        guard let revealViewController =  UIApplication.shared.keyWindow?.rootViewController as? SWRevealViewController else {
            return
        }
        guard let front = revealViewController.frontViewController as? UINavigationController else {
            return
        }
        
        if let view = front.viewControllers.first {
            if view.isKind(of: MailboxViewController.self) ||
                view.isKind(of: ContactsViewController.self) ||
                view.isKind(of: SettingTableViewController.self) {
                self.launchOptions = nil
            }
        }
    }
    
    public func processCachedLaunchOptions() {
        if let options = self.launchOptions {
            self.didReceiveRemoteNotification(options, forceProcess: true, fetchCompletionHandler: { (UIBackgroundFetchResult) -> Void in
            })
            self.launchOptions = nil;
        }
    }
    
    // MARK: - notifications
    
    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], forceProcess : Bool = false, fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if sharedUserDataService.isMailboxPasswordStored {
            let application = UIApplication.shared
            if let messageid = messageIDForUserInfo(userInfo) {
                // if the app is in the background, then switch to the inbox and load the message detail
                if application.applicationState == UIApplication.State.inactive || application.applicationState == UIApplication.State.background || forceProcess {
                    if let revealViewController = application.keyWindow?.rootViewController as? SWRevealViewController {
                        //revealViewController
                        sharedMessageDataService.fetchNotificationMessageDetail(messageid, completion: { (task, response, message, error) -> Void in
                            if error != nil {
                                completionHandler(.failed)
                            } else {
                                if let front = revealViewController.frontViewController as? UINavigationController {
                                    if let mailboxViewController: MailboxViewController = front.viewControllers.first as? MailboxViewController {
                                        sharedMessageDataService.pushNotificationMessageID = messageid
                                        mailboxViewController.performSegueForMessageFromNotification()
                                    } else {
                                    }
                                }
                                completionHandler(.newData)
                            }
                        });
                    } else {
                        completionHandler(.failed)
                    }
                } else {
                    completionHandler(.failed)
                }
            } else {
                completionHandler(.failed)
            }
        }
    }
    
    // MARK: - Private methods
    
    fileprivate func messageIDForUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        
        if let encrypted = userInfo["encryptedMessage"] as? String {
            guard let userkey = sharedUserDataService.userInfo?.firstUserKey(), let password = sharedUserDataService.mailboxPassword else {
                return nil
            }
            do
            {
                guard let plaintext = try encrypted.decryptMessageWithSinglKey(userkey.private_key, passphrase: password) else {
                    return nil
                }
                guard let push = PushData.parse(with: plaintext) else {
                    return nil
                }
                return push.msgID
            } catch {
                return nil
            }
        } else if let object = userInfo["data"] as? [String: Any]  {
            var v : Int?
            if let version = userInfo["version"] as? String {
                v = Int(version)
            }
            let type = userInfo["type"] as? String
            guard let push = PushData.parse(dataDict: object, version: v, type: type) else {
                return nil
            }
            return push.msgID
        } else if let object = userInfo["data"] as? String {
            var v : Int?
            if let version = userInfo["version"] as? String {
                v = Int(version)
            }
            let type = userInfo["type"] as? String
            guard let push = PushData.parse(dataString: object, version: v, type: type) else {
                return nil
            }
            return push.msgID
        } else {
            guard let messageArray = userInfo["message_id"] as? NSArray else {
                return nil
            }
            return messageArray.firstObject as? String
        }
    }
}

extension PushNotificationService {
    internal struct DeviceKey {
        static let token = "DeviceTokenKey"
        static let UID = "DeviceUID"
        
        static let badToken = "DeviceBadToken"
        static let badUID = "DeviceBadUID"
    }
    
    enum Subscription {
        case none // no subscription locally
        case notReported(APIService.PushSubscriptionSettings) // not sent to BE yet
        case pending(APIService.PushSubscriptionSettings) // not on BE yet, but sent there
        case reported(APIService.PushSubscriptionSettings) // this is on BE
    }
}

extension PushNotificationService.Subscription: Codable {
    internal enum CodingKeys: CodingKey {
        case none
        case notReported
        case pending
        case reported
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let settings =  try? container.decode(APIService.PushSubscriptionSettings.self, forKey: .reported) {
            self = .reported(settings)
            return
        }
        if let settings =  try? container.decode(APIService.PushSubscriptionSettings.self, forKey: .pending) {
            self = .pending(settings)
            return
        }
        
        self = .none
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none, .notReported: break // no sence in saving these values - they are pretty useless until sent to BE
        case .pending(let settings): try container.encode(settings, forKey: .pending)
        case .reported(let settings): try container.encode(settings, forKey: .reported)
        }
    }
}
