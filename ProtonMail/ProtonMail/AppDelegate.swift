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
import Firebase


let sharedUserDataService = UserDataService()

@UIApplicationMain
class AppDelegate: UIResponder {
    
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
                        UIView.animate(withDuration: ViewDefined.animationDuration/2,
                                       delay: 0,
                                       options: UIViewAnimationOptions(),
                                       animations: { () -> Void in
                                            rootViewController.view.alpha = 0
                        }, completion: { (finished) -> Void in
                            let viewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                            if let oldView = window.rootViewController as? SWRevealViewController {
                                if let navigation = oldView.frontViewController as? UINavigationController {
                                    if let mailboxViewController: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
                                        mailboxViewController.resetFetchedResultsController()
                                        //TODO:: fix later, this logic change to viewModel service
                                    }
                                }
                            }
                            viewController.view.alpha = 0
                            window.rootViewController = viewController
                            
                            UIView.animate(withDuration: ViewDefined.animationDuration/2,
                                           delay: 0, options: UIViewAnimationOptions(),
                                           animations: { () -> Void in
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
            if let navigation = segue.destination as? UINavigationController {
                if let mailboxViewController: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
                    sharedVMService.mailbox(fromMenu: mailboxViewController, location: .inbox)
                }
            }
        }
    }
}

// MARK: - UIApplicationDelegate

//move to a manager class later
let sharedInternetReachability : Reachability = Reachability.forInternetConnection()
//let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.API_HOST_URL)

extension AppDelegate: UIApplicationDelegate, APIServiceDelegate, UserDataServiceDelegate {
    func onLogout(animated: Bool) {
        self.switchTo(storyboard: .signIn, animated: animated)
    }
    
    func onError(error: NSError) {
        error.alertToast()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.checkOrientation(self.window?.rootViewController)
    }
    
    func checkOrientation (_ viewController: UIViewController?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad || viewController == nil {
            return UIInterfaceOrientationMask.all
        } else if let nav = viewController as? UINavigationController {
            if (nav.topViewController!.isKind(of: PinCodeViewController.self)) {
                return UIInterfaceOrientationMask.portrait
            }
            return UIInterfaceOrientationMask.all
        } else {
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
        FirebaseApp.configure()
        
        // set_messaging_delegate
        Messaging.messaging().delegate = self

//        if #available(iOS 10.0, *) {
//            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self
//
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//        } else {
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            application.registerUserNotificationSettings(settings)
//        }
//        application.registerForRemoteNotifications()
//
        
        shareViewModelFactoy = ViewModelFactoryProduction()
        sharedVMService.cleanLegacy()
        sharedAPIService.delegate = self
        sharedUserDataService.delegate = self
        
        AFNetworkActivityIndicatorManager.shared().isEnabled = true
        
        //get build mode if debug mode enable network logging
        let mode = UIApplication.shared.releaseMode()
        //network debug options
        if let logger = AFNetworkActivityLogger.shared().loggers.first as? AFNetworkActivityConsoleLogger {
            logger.level = .AFLoggerLevelDebug;
        }
        AFNetworkActivityLogger.shared().startLogging()

        //start network notifier
        sharedInternetReachability.startNotifier()
        
        setupWindow()
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedPushNotificationService.registerForRemoteNotifications()
        
        if mode != .dev && mode != .sim {
            AFNetworkActivityLogger.shared().stopLogging()
        }
        
        //setup language
        LanguageManager.setupCurrentLanguage()
        
        return true
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if urlComponents.host == "signup" {
                if let queryItems = urlComponents.queryItems {
                    if let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first {
                        if let code = verifyObject.value {
                            let info : [String:String] = ["verifyCode" : code]
                            let notification = Notification(name: Notification.Name(rawValue: NotificationDefined.CustomizeURLSchema),
                                                            object: nil,
                                                            userInfo: info)
                            NotificationCenter.default.post(notification)
                        }
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
            sharedVMService.resetView()
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: false)
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
        //TODO::here need change to notify composer to save editing draft
        if let context = sharedCoreDataService.mainManagedObjectContext {
            context.perform {
                let _ = context.saveUpstreamIfNeeded()
            }
        }
    }
    
    // MARK: Notification methods
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Answers.logCustomEvent(withName: "NotificationError", customAttributes:["error" : "\(error)"])
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
        Messaging.messaging().apnsToken = deviceToken
        if let token = Messaging.messaging().fcmToken {
            PMLog.D("FCM token: \(token)")
            sharedPushNotificationService.didRegisterForRemoteNotifications(withDeviceToken: token)
        }
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
        let notification = Notification(name: Notification.Name(rawValue: NotificationDefined.TouchStatusBar), object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }
}

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        PMLog.D("Firebase registration token: \(fcmToken)")
        
        sharedPushNotificationService.didRegisterForRemoteNotifications(withDeviceToken: fcmToken)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}

