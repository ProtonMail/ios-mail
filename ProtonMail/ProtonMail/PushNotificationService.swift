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
    
    private var launchOptions: [NSObject: AnyObject]? = nil
    
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
        UIApplication.sharedApplication().unregisterForRemoteNotifications()
        sharedAPIService.deviceUnregister()
    }
    
    
    // MARK: - callback methods
    
    func didFailToRegisterForRemoteNotificationsWithError(error: NSError) {
        NSLog("\(__FUNCTION__) \(error)")
    }
    
    func setLaunchOptions (launchOptions: [NSObject: AnyObject]?) {
        if let launchoption = launchOptions {
            if let option = launchoption["UIApplicationLaunchOptionsRemoteNotificationKey"] as? [NSObject: AnyObject] {
                
                self.launchOptions = option;
                
                NSLog("options : \(self.launchOptions)")
            }
        }
    }
    
    func processCachedLaunchOptions() {
        
        NSLog("process options1 : \(self.launchOptions)")
        
        if let options = self.launchOptions {
            
            
            NSLog("process options2 : \(self.launchOptions)")
            sharedPushNotificationService.didReceiveRemoteNotification(options, forceProcess: true, fetchCompletionHandler: { (UIBackgroundFetchResult) -> Void in
                
            })
            
            self.launchOptions = nil;
        }
    }
    
    func didReceiveRemoteNotification(userInfo: [NSObject : AnyObject], forceProcess : Bool = false, fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        NSLog("did options1 : \(self.launchOptions)")
        if sharedUserDataService.isSignedIn && sharedUserDataService.isMailboxPWDOk {
            
            NSLog("did options2 : \(self.launchOptions)")
            
            let application = UIApplication.sharedApplication()
            if let messageid = messageIDForUserInfo(userInfo) {
                
                NSLog("message \(messageid)")
                
                NSLog("static \(application.applicationState)")
                
                // if the app is in the background, then switch to the inbox and load the message detail
                if application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background || forceProcess {
                    
                    NSLog("ok1 \(messageid)")
                    
                    if let revealViewController = application.keyWindow?.rootViewController as? SWRevealViewController {
                        //revealViewController
                        
                        sharedMessageDataService.fetchNotificationMessageDetail(messageid, completion: { (task, response, message, error) -> Void in
                            if error != nil {
                                completionHandler(.Failed)
                            } else {
                                if let front = revealViewController.frontViewController as? UINavigationController {
                                    if let mailboxViewController: MailboxViewController = front.viewControllers.first as? MailboxViewController {
                                        NSLog("ok2")
                                        mailboxViewController.performSegueForMessageFromNotification(messageid)
                                    }
                                }
                                completionHandler(.NewData)
                            }
                        });
                    }
                }
            }
        }
        
        //TODO :: fix the notification fetch part
        //        sharedMessageDataService.fetchLatestMessagesForLocation(.inbox, completion: { (task, messages, error) -> Void in
        //            if error != nil {
        //                completionHandler(.Failed)
        //            } else if messages != nil && messages!.isEmpty {
        //                completionHandler(.NoData)
        //            } else {
        //                completionHandler(.NewData)
        //            }
        //        })
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
