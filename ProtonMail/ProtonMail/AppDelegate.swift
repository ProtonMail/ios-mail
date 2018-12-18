//
//  AppDelegate.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import SWRevealViewController
import AFNetworking
import AFNetworkActivityLogger
import Keymaker
import UserNotifications
import Intents
import DeviceCheck

let sharedUserDataService = UserDataService()


@UIApplicationMain
class AppDelegate: UIResponder {
    var coordinator = WindowsCoordinator()
}


// MARK: - this is workaround to track when the SWRevealViewController first time load
extension SWRevealViewController {
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "sw_rear") {
            if let menuViewController =  segue.destination as? MenuViewController {
                let viewModel = MenuViewModelImpl()
                let menu = MenuCoordinatorNew(vc: menuViewController, vm: viewModel, services: ServiceFactory.default)
                menu.start()
            }
        } else if (segue.identifier == "sw_front") {
            if let navigation = segue.destination as? UINavigationController {
                if let mailboxViewController: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
                    ///TODO::fixme AppDelegate.coordinator.serviceHolder is bad
                    sharedVMService.mailbox(fromMenu: mailboxViewController)
                    let viewModel = MailboxViewModelImpl(label: .inbox, service: ServiceFactory.default.get(),pushService: ServiceFactory.default.get())
                    let mailbox = MailboxCoordinator(vc: mailboxViewController, vm: viewModel, services: ServiceFactory.default)
                    mailbox.start()                    
                }
            }
        }
    }
}

// MARK: - consider move this to coordinator
extension AppDelegate: APIServiceDelegate, UserDataServiceDelegate {
    func onLogout(animated: Bool) {
        self.coordinator.go(dest: .signInWindow)
    }
    
    func onError(error: NSError) {
        #if DEBUG
        guard #available(iOS 10.0, *) else { return }
        let timeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "🦐 API ERROR"
        content.subtitle = error.localizedDescription
        content.body = error.userInfo.debugDescription
        
        if let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? Data,
            let resObj = String(data: data, encoding: .utf8)
        {
            content.body = resObj + content.body
        }
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: timeTrigger)
        UNUserNotificationCenter.current().add(request) { error in }
        #else
        error.alertToast()
        #endif
    }
}

//move to a manager class later
let sharedInternetReachability : Reachability = Reachability.forInternetConnection()
//let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.API_HOST_URL)

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppVersion.migrate()
        
        Analytics.shared.setup()
        
        #if DEBUG // will fire local notifications on errors instead of toasts
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        #endif
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(300)
        
        ///TODO::fixme refactor
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
        
        ///TODO::fixme we don't need to register remote when start. we only need to register after user logged in
        let pushService = self.coordinator.serviceHolder.get() as PushNotificationService
        pushService.registerForRemoteNotifications()
        pushService.setLaunchOptions(launchOptions)
        
        StoreKitManager.default.subscribeToPaymentQueue()
        StoreKitManager.default.updateAvailableProductsList()
        
        if #available(iOS 12.0, *) {
            let intent = WipeMainKeyIntent()
            let suggestions = [INShortcut(intent: intent)!]
            INVoiceShortcutCenter.shared.setShortcutSuggestions(suggestions)
        if #available(iOS 11.0, *) {
            self.generateToken()
        }
        
        self.coordinator.start()
        return true
    }
    
    @available(iOS 11.0, *)
    func generateToken(){
        let currentDevice = DCDevice.current
        if currentDevice.isSupported {
            currentDevice.generateToken(completionHandler: { (data, error) in
                DispatchQueue.main.async {
                    if let tokenData = data {
                        PMLog.D(tokenData.base64EncodedString())
                    }
                }
            })
        }
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
        ///TODO::fixme change to deeplink
        let info : [String:String] = ["verifyCode" : code]
        let notification = Notification(name: .customUrlSchema,
                                        object: nil,
                                        userInfo: info)
        NotificationCenter.default.post(notification)
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        keymaker.updateAutolockCountdownStart()
        sharedMessageDataService.purgeOldMessages()
        
        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask { PMLog.D("Background Task Timed Out") }
        let delayedCompletion: ()->Void = {
            delay(3) {
                PMLog.D("End Background Task")
                application.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: taskID.rawValue))
            }
        }
        
        if SignInManager.shared.isSignedIn() {
            sharedMessageDataService.backgroundFetch { delayedCompletion() }
        } else {
            delayedCompletion()
        }
        PMLog.D("Enter Background")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        //TODO::here need change to notify composer to save editing draft
        let mainContext = sharedCoreDataService.mainManagedObjectContext
        mainContext.performAndWait {
            let _ = mainContext.saveUpstreamIfNeeded()
        }
        
        let backgroundContext = sharedCoreDataService.mainManagedObjectContext
        backgroundContext.performAndWait {
            let _ = backgroundContext.saveUpstreamIfNeeded()
        }
    }
    
    // MARK: Background methods
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // this feature can only work if user did not lock the app
        guard SignInManager.shared.isSignedIn(), UnlockManager.shared.isUnlocked() else {
            completionHandler(.noData)
            return
        }
        sharedMessageDataService.backgroundFetch {
            completionHandler(.newData)
        }
    }
    
    // MARK: Notification methods
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Analytics.shared.logCustomEvent(withName: "NotificationError", customAttributes:["error" : "\(error)"])
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PMLog.D("receive \(userInfo)")
        ///TODO::fixme deep link
        let pushService = self.coordinator.serviceHolder.get() as PushNotificationService
        if UnlockManager.shared.isUnlocked() {
            pushService.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        } else {
            pushService.setNotificationOptions(userInfo)
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PMLog.D(deviceToken.stringFromToken())
        let pushService = self.coordinator.serviceHolder.get() as PushNotificationService
        pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
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

#if DEBUG
@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        // Display notification as regular alert and play sound
        completionHandler([.alert, .sound])
    }
}
#endif
