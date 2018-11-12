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
    
    //FIXME: tempory
    var upgradeView : ForceUpgradeView?
    
    // FIXME: this is new navigation system Router's work
    lazy var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController() // simple black background for animation in switchTo(_:_:) method
        window.makeKeyAndVisible()
        return window
    }()
    
    // FIXME: this is new navigation system Router's work
    @objc func setupWindow(gotMainKey: Bool) {
        guard SignInManager.shared.isSignedIn() else {
            self.switchTo(storyboard: .signIn, animated: false)
            return
        }
        
        switch gotMainKey {
        case true: self.switchTo(storyboard: .inbox, animated: true)
        case false: self.switchTo(storyboard: .signIn, animated: true)
        }
    }
    
    @objc func lockWindow() {
        self.setupWindow(gotMainKey: false)
    }
    
    @objc func unlockWindow() {
        self.setupWindow(gotMainKey: true)
    }
    
    // MARK: - Public methods
    
    // FIXME: this is new navigation system Router's work
    func switchTo(storyboard: UIStoryboard.Storyboard, animated: Bool) {
        DispatchQueue.main.async {
            guard let window = self.window else {
                return
            }
            
            guard let rootViewController = window.rootViewController,
                rootViewController.restorationIdentifier != storyboard.restorationIdentifier else {
                return
            }
            
            if !animated {
                window.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
            } else {
                UIView.animate(withDuration: ViewDefined.animationDuration/2,
                               delay: 0,
                               options: UIView.AnimationOptions(),
                               animations: { () -> Void in
                                rootViewController.view.alpha = 0
                }, completion: { (finished) -> Void in
                    guard let viewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard) else {
                        return
                    }
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
                                   delay: 0, options: UIView.AnimationOptions(),
                                   animations: { () -> Void in
                                    viewController.view.alpha = 1.0
                    }, completion: nil)
                })
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
        
        
        //TODO:: Tempory later move it into App coordinator
        NotificationCenter.default.addObserver(self, selector: #selector(performForceUpgrade), name: .forceUpgrade, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(lockWindow), name: Keymaker.requestMainKey, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(unlockWindow), name: Keymaker.obtainedMainKey, object: nil)
        
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
        Snapshot().didEnterBackground(application)
        keymaker.updateAutolockCountdownStart()
        
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
        if keymaker.mainKey == nil {
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
            let point = touch.location(in: self.window)
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
    
    @objc func performForceUpgrade(_ notification: Notification) {
        guard let keywindow = UIApplication.shared.keyWindow else {
            return
        }
        
        if let exsitView = upgradeView {
            keywindow.bringSubviewToFront(exsitView)
            return
        }
        
        let view = ForceUpgradeView(frame: keywindow.bounds)
        self.upgradeView = view
        if let msg = notification.object as? String {
            view.messageLabel.text = msg
        }
        view.delegate = self
        UIView.transition(with: keywindow, duration: 0.25,
                          options: .transitionCrossDissolve, animations: {
            keywindow.addSubview(view)
        }, completion: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.rotated),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    @objc func rotated() {
        if let view = self.upgradeView {
            guard let keywindow = UIApplication.shared.keyWindow else {
                return
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.0,
                           options: UIView.AnimationOptions.layoutSubviews, animations: {
                view.frame = keywindow.frame
                view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

extension AppDelegate : ForceUpgradeViewDelegate {
    func learnMore() {
        if UIApplication.shared.canOpenURL(.kbUpdateRequired) {
            UIApplication.shared.openURL(.kbUpdateRequired)
        }
    }
    func update() {
        if UIApplication.shared.canOpenURL(.appleStore) {
            UIApplication.shared.openURL(.appleStore)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIBackgroundTaskIdentifier(_ input: Int) -> UIBackgroundTaskIdentifier {
	return UIBackgroundTaskIdentifier(rawValue: input)
}
