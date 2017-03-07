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
    
    fileprivate let animationDuration: TimeInterval = 0.5
    
    // FIXME: Before this code is shared publicly, inject the API key from the build command.
    
    fileprivate let mintAPIKey = "2b423dec"
    
    var window: UIWindow?
    
    func instantiateRootViewController() -> UIViewController {
        let storyboard = UIStoryboard.Storyboard.signIn
        return UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
    }
    
    func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = instantiateRootViewController()
        window?.makeKeyAndVisible()
    }
    
    // MARK: - Public methods
    func switchTo(storyboard: UIStoryboard.Storyboard, animated: Bool) {
        if let window = window {
            if let rootViewController = window.rootViewController {
                if rootViewController.restorationIdentifier != storyboard.restorationIdentifier {
                    if !animated {
                        window.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                    } else {
                        UIView.animate(withDuration: animationDuration/2, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
                            rootViewController.view.alpha = 0
                            }, completion: { (finished) -> Void in
                                let viewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                                
                                if let oldView = window.rootViewController as? SWRevealViewController {
                                    if let nav = oldView.frontViewController as? UINavigationController {
                                        if let firstViewController: UIViewController = nav.viewControllers.first as UIViewController? {
                                            if (firstViewController.isKind(of: MailboxViewController.self)) {
                                                if let mailboxViewController: MailboxViewController = firstViewController as? MailboxViewController {
                                                    mailboxViewController.resetFetchedResultsController()
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                viewController.view.alpha = 0
                                window.rootViewController = viewController
                                
                                UIView.animate(withDuration: self.animationDuration/2, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
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
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "sw_front") {
            let navigationController = segue.destination as! UINavigationController
            if let firstViewController: UIViewController = navigationController.viewControllers.first as UIViewController? {
                if (firstViewController.isKind(of: MailboxViewController.self)) {
                    let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                    mailboxViewController.viewModel = MailboxViewModelImpl(location: .inbox)
                }
            }
        }
    }
}

// MARK: - UIApplicationDelegate

//move to a manager class later
let sharedInternetReachability : Reachability = Reachability.forInternetConnection()
let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.API_HOST_URL)

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.checkOrientation(self.window?.rootViewController)
    }
    
    func checkOrientation (_ viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad || viewController == nil {
            return UIInterfaceOrientationMask.all
        } else if (viewController is UINavigationController) {
            if let nav = viewController as? UINavigationController {
                if (nav.topViewController!.isKind(of: PinCodeViewController.self)) {
                    return UIInterfaceOrientationMask.portrait
                }
            }
            return UIInterfaceOrientationMask.all
        }
        else {
            if let sw = viewController as? SWRevealViewController {
                if let nav = sw.frontViewController as? UINavigationController {
                    if (nav.topViewController!.isKind(of: PinCodeViewController.self)) {
                        return UIInterfaceOrientationMask.portrait
                    }
                }
            }
            return  UIInterfaceOrientationMask.all
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics()])
        
        shareViewModelFactoy = ViewModelFactoryProduction()
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
        
        let tmp = UIApplication.shared.releaseMode()
        //net work debug option
        if let logger = AFNetworkActivityLogger.shared().loggers.first as? AFNetworkActivityConsoleLogger {
            logger.level = .AFLoggerLevelDebug;
        }
        AFNetworkActivityLogger.shared().startLogging()
        
        //
        sharedInternetReachability.startNotifier()
        
        setupWindow()
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedPushNotificationService.registerForRemoteNotifications()
        
        if tmp != .dev && tmp != .sim {
            AFNetworkActivityLogger.shared().stopLogging()
        }
        sharedPushNotificationService.setLaunchOptions(launchOptions)
        
        return true
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if urlComponents?.host == "signup" {
            if let queryItems = urlComponents?.queryItems {
                if let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first {
                    if let code = verifyObject.value {
                        let info : [String:String] = ["verifyCode" : code]
                        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NotificationDefined.CustomizeURLSchema), object: nil, userInfo: info))
                        PMLog.D("\(code)")
                    }
                }
            }
        }
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Snapshot().didEnterBackground(application)
        if sharedUserDataService.isSignedIn {
            let timeInterval : Int = Int(Date().timeIntervalSince1970)
            userCachedStatus.exitTime = "\(timeInterval)";
        }
        sharedMessageDataService.purgeOldMessages()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Snapshot().willEnterForeground(application)
        if sharedTouchID.showTouchIDOrPin() {
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: false)
            sharedVMService.resetComposerView()
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        let _ = sharedCoreDataService.mainManagedObjectContext?.saveUpstreamIfNeeded()
    }
    
    // MARK: Notification methods
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Answers.logCustomEvent(withName: "NotificationError", customAttributes:["error" : "\(error)"])
        
        // Crashlytics.sharedInstance().core.log(error);
        sharedPushNotificationService.didFailToRegisterForRemoteNotificationsWithError(error as NSError)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
                let timeInterval : Int = Int(Date().timeIntervalSince1970)
                let diff = timeInterval - exitTime
                if diff > (timeIndex*60) || diff <= 0 {
                    sharedPushNotificationService.setNotificationOptions(userInfo);
                } else {
                    sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
                }
            } else {
                sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
            }
        } else {
            sharedPushNotificationService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        }
        
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        sharedPushNotificationService.didRegisterUserNotificationSettings(notificationSettings)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        sharedPushNotificationService.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first as UITouch!
        let point = touch?.location(in: self.window)
        let statusBarFrame = UIApplication.shared.statusBarFrame
        if (statusBarFrame.contains(point!)) {
            self.touchStatusBar()
        }
    }
    
    func touchStatusBar() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NotificationDefined.TouchStatusBar), object: nil, userInfo: nil))
    }
}

