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
import SWRevealViewController
import AFNetworking
import AFNetworkActivityLogger
import Keymaker

let sharedUserDataService = UserDataService()

@UIApplicationMain
class AppDelegate: UIResponder {
    lazy var coordinator = WindowsCoordinator()
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
        self.coordinator.go(dest: .signInWindow)
    }
    
    func onError(error: NSError) {
        error.alertToast()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.checkOrientation(window?.rootViewController)
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
            return .all
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppVersion.current.migration()
        
        Fabric.with([Crashlytics()])
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(300)
        
        shareViewModelFactoy = ViewModelFactoryProduction()
        sharedVMService.cleanLegacy()
        sharedAPIService.delegate = self
        
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
        
        sharedMessageDataService.launchCleanUpIfNeeded()
        sharedUserDataService.delegate = self
        
        if mode != .dev && mode != .sim {
            AFNetworkActivityLogger.shared().stopLogging()
        }
         AFNetworkActivityLogger.shared().stopLogging()
        //setup language
        LanguageManager.setupCurrentLanguage()
        
        PushNotificationService.shared.registerForRemoteNotifications()
        PushNotificationService.shared.setLaunchOptions(launchOptions)
        
        StoreKitManager.default.subscribeToPaymentQueue()
        StoreKitManager.default.updateAvailableProductsList()
        
        self.coordinator.start()
        
        return true
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true), urlComponents.host == "signup" else {
            return false
        }
        
        guard let queryItems = urlComponents.queryItems, let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first else {
            return false
        }
        
        guard let code = verifyObject.value else {
            return false
        }
        
        let info : [String:String] = ["verifyCode" : code]
        let notification = Notification(name: Notification.Name(rawValue: NotificationDefined.CustomizeURLSchema),
                                        object: nil,
                                        userInfo: info)
        NotificationCenter.default.post(notification)
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        keymaker.updateAutolockCountdownStart()
        Snapshot().didEnterBackground(application)
        
        var taskID : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask {
            //timed out
        }
        sharedMessageDataService.purgeOldMessages()
        if sharedUserDataService.isUserCredentialStored {
            sharedMessageDataService.backgroundFetch {
                delay(3, closure: {
                    PMLog.D("End Background Task")
                    application.endBackgroundTask(convertToUIBackgroundTaskIdentifier(taskID.rawValue))
                })
            }
        } else {
            delay(3, closure: {
                application.endBackgroundTask(convertToUIBackgroundTaskIdentifier(taskID.rawValue))
            })
        }
        
        PMLog.D("Enter Background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Snapshot().willEnterForeground(application)
        let _ = keymaker.mainKey
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
    
    // MARK: Background methods`
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if sharedUserDataService.isUserCredentialStored {
            //sharedMessageDataService.fetchNewMessagesForLocation(.inbox, notificationMessageID: nil) { (task, nil, nil ) in
            sharedMessageDataService.backgroundFetch {
                completionHandler(.newData)
            }
        } else {
            completionHandler(.noData)
        }
    }
    
    // MARK: Notification methods
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Answers.logCustomEvent(withName: "NotificationError", customAttributes:["error" : "\(error)"])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PMLog.D("receive \(userInfo)")

        if let _ = keymaker.mainKey { // means app is unlocked
            PushNotificationService.shared.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        } else {
            PushNotificationService.shared.setNotificationOptions(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationService.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: UIApplication.shared.keyWindow)
            let statusBarFrame = UIApplication.shared.statusBarFrame
            if (statusBarFrame.contains(point)) {
                self.touchStatusBar()
            }
        }
    }
    
    func touchStatusBar() {
        let notification = Notification(name: .touchStatusBar, object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIBackgroundTaskIdentifier(_ input: Int) -> UIBackgroundTaskIdentifier {
	return UIBackgroundTaskIdentifier(rawValue: input)
}
