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

public let sharedPushNotificationService = PushNotificationService()

public class PushNotificationService {
    
    fileprivate var launchOptions: [AnyHashable: Any]? = nil
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(PushNotificationService.didSignInNotification(_:)), name: NSNotification.Name(rawValue: NotificationDefined.didSignIn), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PushNotificationService.didSignOutNotification(_:)), name: NSNotification.Name(rawValue: NotificationDefined.didSignOut), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - registration methods
    
    public func registerUserNotificationSettings() {
        let types: UIUserNotificationType = [.badge , .sound , .alert]
        let settings = UIUserNotificationSettings(types: types, categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
    }
    
    public func registerForRemoteNotifications() {
        if sharedUserDataService.isSignedIn {
           UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    public func unregisterForRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
        sharedAPIService.deviceUnregister()
    }
    
    
    // MARK: - callback methods
    
    public func didFailToRegisterForRemoteNotificationsWithError(_ error: NSError) {
        PMLog.D(" \(error)")
    }
    
    public func setLaunchOptions (_ launchOptions: [AnyHashable: Any]?) {
        if let launchoption = launchOptions {
            if let option = launchoption["UIApplicationLaunchOptionsRemoteNotificationKey"] as? [AnyHashable: Any] {
                self.launchOptions = option;
            }
        }
    }
    
    public func setNotificationOptions (_ userInfo: [AnyHashable: Any]?) {
        self.launchOptions = userInfo;
    }
    
    public func processCachedLaunchOptions() {
        if let options = self.launchOptions {
            sharedPushNotificationService.didReceiveRemoteNotification(options, forceProcess: true, fetchCompletionHandler: { (UIBackgroundFetchResult) -> Void in
            })
            self.launchOptions = nil;
        }
    }
    
    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], forceProcess : Bool = false, fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if sharedUserDataService.isSignedIn && sharedUserDataService.isMailboxPWDOk {
            let application = UIApplication.shared
            if let messageid = messageIDForUserInfo(userInfo) {
                // if the app is in the background, then switch to the inbox and load the message detail
                if application.applicationState == UIApplicationState.inactive || application.applicationState == UIApplicationState.background || forceProcess {
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
                    }
                }
            }
        }
    }
    
    public func didRegisterForRemoteNotificationsWithDeviceToken(_ deviceToken: Data) {
        sharedAPIService.cleanBadKey(deviceToken)
        sharedAPIService.deviceRegisterWithToken(deviceToken, completion: { (_, _, error) -> Void in
            if let error = error {
                PMLog.D(" error: \(error)")
            }
        })
    }
    
    public func didRegisterUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings) {
        
    }
    
    
    // MARK: - Notifications
    
    @objc public func didSignInNotification(_ notification: Notification) {
        registerUserNotificationSettings()
        registerForRemoteNotifications()
    }
    
    @objc public func didSignOutNotification(_ notification: Notification) {
        unregisterForRemoteNotifications()
    }
    
    
    // MARK: - Private methods
    
    fileprivate func messageIDForUserInfo(_ userInfo: [AnyHashable: Any]) -> String? {
        let messageArray = userInfo["message_id"] as? NSArray
        return messageArray?.firstObject as? String
    }
}
