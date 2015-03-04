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
    
    // MARK: - callback methods
    
    func didFailToRegisterForRemoteNotificationsWithError(error: NSError) {
        NSLog("\(__FUNCTION__) \(error)")
    }
    
    func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
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
        // TODO: post to server
    }
    
    func didRegisterUserNotificationSettings(notificationSettings: UIUserNotificationSettings) {
        
    }
    
    // MARK: - Notifications
    
    @objc func didSignInNotification(notification: NSNotification) {
        registerUserNotificationSettings()
        registerForRemoteNotifications()
    }
    
    @objc func didSignOutNotification(notification: NSNotification) {
        // TODO: unregister remote token with server
    }
}
