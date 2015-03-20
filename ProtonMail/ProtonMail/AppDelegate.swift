//
//  AppDelegate.swift
//  ProtonMail
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    
    private let animationDuration: NSTimeInterval = 0.5
    
    // FIXME: Before this code is shared publicly, inject the API key from the build command.
    private let mintAPIKey = "2b423dec"
    
    var window: UIWindow?
    
    func instantiateRootViewController() -> UIViewController {
        let storyboard = UIStoryboard.Storyboard.signIn
        return UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
    }

    func setupWindow() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = instantiateRootViewController()
        window?.makeKeyAndVisible()
    }
        
    // MARK: - Public methods
    
    func switchTo(#storyboard: UIStoryboard.Storyboard, animated: Bool) {
        if let window = window {
            if let rootViewController = window.rootViewController {
                if rootViewController.restorationIdentifier != storyboard.restorationIdentifier {
                    let animations: () -> Void = {
                        window.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                    }
                    
                    if animated {
                        UIView.transitionWithView(window, duration: animationDuration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: animations, completion: nil)
                    } else {
                        animations()
                    }
                }
            }
        }
    }
}


// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Mint.sharedInstance().enableLogging(true)
        Mint.sharedInstance().setLogging(8)
        Mint.sharedInstance().initAndStartSession(mintAPIKey)
        
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        setupWindow()
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedPushNotificationService.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        Snapshot().didEnterBackground(application)
        
        sharedMessageDataService.purgeOldMessages()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        Snapshot().willEnterForeground(application)
        
        if sharedUserDataService.isSignedIn {
            
            sharedUserDataService.fetchUserInfo()
            sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
                if error != nil {
                    NSLog("\(error)")
                } else {
                    NSLog("Contacts count: \(contacts!.count)")
                }
            })
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        sharedCoreDataService.mainManagedObjectContext?.saveUpstreamIfNeeded()
    }
    
    // MARK: Notification methods
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        sharedPushNotificationService.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background {
            var messageArray = userInfo["message_id"] as? NSArray
            var messageId = messageArray?.firstObject as? String
            
            if let messageId = messageId {
                var message = Message.messageForMessageID(messageId, inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext!)
                var detailViewController: MessageDetailViewController = MessageDetailViewController()
                detailViewController.message = message
                var windowRootViewController = self.window?.rootViewController
                var revealViewController: SWRevealViewController = windowRootViewController as SWRevealViewController
                var navigationController: UINavigationController = revealViewController.frontViewController as UINavigationController
                var presentedViewController = navigationController.presentedViewController
                
                if let presentedViewController = presentedViewController {
                    presentedViewController.dismissViewControllerAnimated(false, completion: nil)
                }
                navigationController.pushViewController(detailViewController, animated: true)
            }
        }

        sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        sharedPushNotificationService.didRegisterUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        sharedPushNotificationService.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
}

