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
    func switchTo(storyboard storyboard: UIStoryboard.Storyboard, animated: Bool) {
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
                                        if let firstViewController: UIViewController = nav.viewControllers.first as UIViewController? {
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
            if let firstViewController: UIViewController = navigationController.viewControllers.first as UIViewController? {
                if (firstViewController.isKindOfClass(MailboxViewController)) {
                    let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                    mailboxViewController.viewModel = MailboxViewModelImpl(location: .inbox)
                }
            }
        }
    }
}

// MARK: - UIApplicationDelegate

//move to a manager class later
let sharedInternetReachability : Reachability = Reachability.reachabilityForInternetConnection()
let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.BaseURLString)

extension AppDelegate: UIApplicationDelegate {
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.checkOrientation(self.window?.rootViewController)
    }
    
    func checkOrientation (viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad || viewController == nil {
            return UIInterfaceOrientationMask.All
        } else if (viewController is UINavigationController) {
            if let nav = viewController as? UINavigationController {
                if (nav.topViewController!.isKindOfClass(PinCodeViewController)) {
                    return UIInterfaceOrientationMask.Portrait
                }
            }
            return UIInterfaceOrientationMask.All
        }
        else {
            if let sw = viewController as? SWRevealViewController {
                if let nav = sw.frontViewController as? UINavigationController {
                    if (nav.topViewController!.isKindOfClass(PinCodeViewController)) {
                        return UIInterfaceOrientationMask.Portrait
                    }
                }
            }
            return  UIInterfaceOrientationMask.All
        }
    }
    
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
        
        //sharedRemoteReachability.startNotifier()
        sharedInternetReachability.startNotifier()

        
        setupWindow()
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedPushNotificationService.registerForRemoteNotifications()
        
        let tmp = UIApplication.sharedApplication().releaseMode()
        if tmp != .Dev && tmp != .Sim {
            AFNetworkActivityLogger.sharedLogger().stopLogging()
        }
        sharedPushNotificationService.setLaunchOptions(launchOptions)
        
        
        PMLog.D("\(UIScreen.mainScreen().bounds)")
        
        return true
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        //let dict = [String, String]
        //let url = "http://example.com?param1=value1&param2=param2"
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)
        if urlComponents?.host == "signup" {
            if let queryItems = urlComponents?.queryItems {
                if let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first {
                    if let code = verifyObject.value {
                        let info : [String:String] = ["verifyCode" : code]
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NotificationDefined.CustomizeURLSchema, object: nil, userInfo: info))
                        PMLog.D("\(code)")
                    }
                }
            }
        }
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        Snapshot().didEnterBackground(application)
        let timeInterval : Int = Int(NSDate().timeIntervalSince1970)
        userCachedStatus.exitTime = "\(timeInterval)";
        sharedMessageDataService.purgeOldMessages()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        Snapshot().willEnterForeground(application)
        
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            var timeIndex : Int = -1
            if let t = Int(userCachedStatus.lockTime) {
                timeIndex = t
            }
            if timeIndex == 0 {
                (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: false)
                sharedVMService.resetComposerView()
            } else if timeIndex > 0 {
                var exitTime : Int = 0
                if let t = Int(userCachedStatus.exitTime) {
                    exitTime = t
                }
                let timeInterval : Int = Int(NSDate().timeIntervalSince1970)
                let diff = timeInterval - exitTime
                if diff > (timeIndex*60) || diff <= 0 {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: false)
                    sharedVMService.resetComposerView()
                }
            }
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
        Answers.logCustomEventWithName("NotificationError", customAttributes:["error" : "\(error)"])
        
        // Crashlytics.sharedInstance().core.log(error);
        sharedPushNotificationService.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        PMLog.D("receive \(userInfo)")
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            var timeIndex : Int = -1
            if let t = Int(userCachedStatus.lockTime) {
                timeIndex = t
            }
            if timeIndex == 0 {
                sharedPushNotificationService.setNotificationOptions(userInfo);
            } else if timeIndex > 0 {
                var exitTime : Int = 0
                if let t = Int(userCachedStatus.exitTime) {
                    exitTime = t
                }
                let timeInterval : Int = Int(NSDate().timeIntervalSince1970)
                let diff = timeInterval - exitTime
                if diff > (timeIndex*60) || diff <= 0 {
                    sharedPushNotificationService.setNotificationOptions(userInfo);
                } else {
                    sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
                }
            }
        } else {
            sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        }
        
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        sharedPushNotificationService.didRegisterUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        sharedPushNotificationService.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first as UITouch!
        let point = touch.locationInView(self.window)
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        if (CGRectContainsPoint(statusBarFrame, point)) {
            self.touchStatusBar()
        }
    }
    
    func touchStatusBar() {
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: NotificationDefined.TouchStatusBar, object: nil, userInfo: nil))
    }
}

