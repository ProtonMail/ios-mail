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
import Fabric
import Crashlytics

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
                    if !animated {
                        window.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                    } else {
                        UIView.animateWithDuration(animationDuration/2, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                            rootViewController.view.alpha = 0
                            }, completion: { (finished) -> Void in
                                let viewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                                
                                if let oldView = window.rootViewController as? SWRevealViewController {
                                    if let nav = oldView.frontViewController as? UINavigationController {
                                        if let firstViewController: UIViewController = nav.viewControllers.first as? UIViewController {
                                            if (firstViewController.isKindOfClass(MailboxViewController)) {
                                                if let mailboxViewController: MailboxViewController = firstViewController as? MailboxViewController {
                                                    mailboxViewController.resetFetchedResultsController()
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                viewController.view.alpha = 0
                                window.rootViewController = viewController
                                
                                UIView.animateWithDuration(self.animationDuration/2, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                    viewController.view.alpha = 1.0
                                    }, completion: nil)
                        })
                    }
                }
            }
        }
    }
}

extension SWRevealViewController {
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "sw_front") {
            let navigationController = segue.destinationViewController as! UINavigationController
            if let firstViewController: UIViewController = navigationController.viewControllers.first as? UIViewController {
                if (firstViewController.isKindOfClass(MailboxViewController)) {
                    let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                    mailboxViewController.viewModel = MailboxViewModelImpl(location: .inbox)
                }
            }
        }
    }
}

// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {
//    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> Int {
//        if self.window?.rootViewController?.presentedViewController is QuickViewViewController {
//            let secondController = self.window!.rootViewController!.presentedViewController as! QuickViewViewController
//            if secondController.isPresented {
//                return Int(UIInterfaceOrientationMask.All.rawValue);
//            } else {
//                return Int(UIInterfaceOrientationMask.Portrait.rawValue);
//            }
//        } else {
//            return Int(UIInterfaceOrientationMask.Portrait.rawValue | UIInterfaceOrientationMask.PortraitUpsideDown.rawValue);
//        }
//    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Fabric.with([Crashlytics()])
        //
        //        let sharedCache = NSURLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        //        NSURLCache.setSharedURLCache(sharedCache)
        //
        shareViewModelFactoy = ViewModelFactoryProduction()
        
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        
        //net work debug option
        AFNetworkActivityLogger.sharedLogger().startLogging()
        AFNetworkActivityLogger.sharedLogger().level = AFHTTPRequestLoggerLevel.AFLoggerLevelDebug
        AFNetworkActivityLogger.sharedLogger().stopLogging()
        
        setupWindow()
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedPushNotificationService.registerForRemoteNotifications()
        
        let tmp = UIApplication.sharedApplication().releaseMode()
        if tmp != .Dev && tmp != .Sim {
            AFNetworkActivityLogger.sharedLogger().stopLogging()
        }
        
        sharedPushNotificationService.setLaunchOptions(launchOptions)
        
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        let dict = [String, String]()
        //let url = "http://example.com?param1=value1&param2=param2"
        
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) //NSURLComponents(string: url)
        let queryItems = urlComponents?.queryItems
        let param1 = queryItems?.filter({$0.name == "param1"}).first
        print("\(param1)")
        
        
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NotificationDefined.CustomizeURLSchema, object: nil, userInfo: nil))
        
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
        Answers.logCustomEventWithName("NotificationError", customAttributes:["error" : "\(error)"])
        
        // Crashlytics.sharedInstance().core.log(error);
        sharedPushNotificationService.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        NSLog("receive \(userInfo)")
        sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        sharedPushNotificationService.didRegisterUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        sharedPushNotificationService.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        var touch = touches.first as! UITouch
        var point = touch.locationInView(self.window)
        var statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        if (CGRectContainsPoint(statusBarFrame, point)) {
            self.touchStatusBar()
        }
        
    }
    
    func touchStatusBar() {
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NotificationDefined.TouchStatusBar, object: nil, userInfo: nil))
    }
}

