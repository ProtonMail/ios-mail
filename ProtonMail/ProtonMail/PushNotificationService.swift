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

let sharedPushNotificationService = PushNotificationService()

class PushNotificationService {
    
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSignInNotification:", name: UserDataService.Notification.didSignIn, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSignOutNotification:", name: UserDataService.Notification.didSignOut, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - registration methods
    
    func registerUserNotificationSettings() {
        let types: UIUserNotificationType = .Badge | .Sound | .Alert
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    func registerForRemoteNotifications() {
        if sharedUserDataService.isSignedIn {
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }
    }
    
    func unregisterForRemoteNotifications() {
        sharedAPIService.deviceUnregister()
    }
    
    
    // MARK: - callback methods
    
    func didFailToRegisterForRemoteNotificationsWithError(error: NSError) {
        NSLog("\(__FUNCTION__) \(error)")
    }
    
    func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        let application = UIApplication.sharedApplication()
        
        // if the app is in the background, then switch to the inbox and load the message detail
        if application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background {
            if let revealViewController = application.keyWindow?.rootViewController as? SWRevealViewController {
                
                //revealViewController
                
//                if let navigationController = revealViewController.storyboard?.instantiateViewControllerWithIdentifier("MailboxNavigationController") as? UINavigationController {
//                    revealViewController.frontViewController = navigationController
//                    
//                    if let mailboxViewController = navigationController.topViewController as? MailboxViewController {
//                        mailboxViewController.mailboxLocation = .inbox
//                        mailboxViewController.messageID = messageIDForUserInfo(userInfo)
//                    }
//                }
            }
        }
        
        sharedMessageDataService.fetchLatestMessagesForLocation(.inbox, completion: { (task, messages, error) -> Void in
            if error != nil {
                completionHandler(.Failed)
            } else if messages != nil && messages!.isEmpty {
                completionHandler(.NoData)
            } else {
                completionHandler(.NewData)
            }
        })
    }
    
    func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: NSData) {
        sharedAPIService.deviceRegisterWithToken(deviceToken, completion: { (_, _, error) -> Void in
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        })
    }
    
    func didRegisterUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        
    }
    
    
    // MARK: - Notifications
    
    @objc func didSignInNotification(notification: NSNotification) {
        registerUserNotificationSettings()
        registerForRemoteNotifications()
    }
    
    @objc func didSignOutNotification(notification: NSNotification) {
        unregisterForRemoteNotifications()
    }
    
    
    // MARK: - Private methods
    
    private func messageIDForUserInfo(userInfo: [NSObject : AnyObject]) -> String? {
        let messageArray = userInfo["message_id"] as? NSArray
        return messageArray?.firstObject as? String
    }
}
