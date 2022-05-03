//
//  AppDelegate.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import UserNotifications
import Intents
import SideMenuSwift
import ProtonCore_Keymaker
import ProtonCore_Networking
import ProtonCore_Payments
import ProtonCore_Services
import ProtonCore_UIFoundations

let sharedUserDataService = UserDataService(api: PMAPIService.unauthorized)

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow? { // this property is important for State Restoration of modally presented viewControllers
        return self.coordinator.currentWindow
    }
    lazy var coordinator: WindowsCoordinator = WindowsCoordinator(services: sharedServices, darkModeCache: userCachedStatus)
    private var currentState: UIApplication.State = .active
    private var hasConfigureForWillLaunch = false
    private var hasConfigureForDidLaunch = false
}

// MARK: - consider move this to coordinator
extension AppDelegate: UserDataServiceDelegate {
    func onLogout(animated: Bool) {
        if #available(iOS 13.0, *) {
            let sessions = Array(UIApplication.shared.openSessions)
            let oneToStay = sessions.first(where: { $0.scene?.delegate as? WindowSceneDelegate != nil })
            (oneToStay?.scene?.delegate as? WindowSceneDelegate)?.coordinator.go(dest: .signInWindow(.form))

            for session in sessions where session != oneToStay {
                UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { _ in }
            }
        } else {
            self.coordinator.go(dest: .signInWindow(.form))
        }
    }
}

extension AppDelegate: APIServiceDelegate {
    var additionalHeaders: [String: String]? { nil }

    var locale: String {
        return LanguageManager.currentLanguageCode()
    }

    func isReachable() -> Bool {
        #if !APP_EXTENSION
        return sharedInternetReachability.currentReachabilityStatus() != NetworkStatus.NotReachable
        #else
        return sharedInternetReachability.currentReachabilityStatus() != NetworkStatus.NotReachable
        #endif
    }

    func onUpdate(serverTime: Int64) {
        MailCrypto.updateTime(serverTime, processInfo: userCachedStatus)
    }

    var appVersion: String {
        get {
            return "iOS_\(Bundle.main.majorVersion)"
        }
    }

    var userAgent: String? {
        UserAgent.default.ua
    }

    func onDohTroubleshot() { }
}

extension AppDelegate: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        let currentWindow: UIWindow? = {
            if #available(iOS 13.0, *) {
                let session = UIApplication.shared.openSessions.first { $0.scene?.activationState == UIScene.ActivationState.foregroundActive }
                let scene = session?.scene as? UIWindowScene
                let window = scene?.windows.first
                return window
            } else {
                return self.window
            }
        }()

        guard let top = currentWindow?.topmostViewController(), !(top is UIAlertController) else { return }
        top.present(alert, animated: true, completion: nil)
    }
}

//move to a manager class later
let sharedInternetReachability: Reachability = Reachability.forInternetConnection()
//let sharedRemoteReachability : Reachability = Reachability(hostName: AppConstants.API_HOST_URL)

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let message = "\(#function) data available: \(UIApplication.shared.isProtectedDataAvailable)"
        SystemLogger.log(message: message, category: .appLifeCycle)

        guard application.isProtectedDataAvailable else {
            // pre-warm, don't do anything
            return false
        }
        self.configForWillLaunch()
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SystemLogger.log(message: #function, category: .appLifeCycle)
        guard application.isProtectedDataAvailable else {
            NotificationCenter.default
                .addObserver(forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                             object: nil,
                             queue: .main) { [weak self] _ in
                    self?.configForWillLaunch()
                    self?.configForDidLaunch(launchOptions: launchOptions)
                }
            return false
        }
        self.configForDidLaunch(launchOptions: launchOptions)
        return true
    }

    @objc fileprivate func didSignOutNotification(_ notification: Notification) {
        self.onLogout(animated: false)
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.scene(_:openURLContexts:)" )
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return self.application(app, handleOpen: url)
    }

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.scene(_:openURLContexts:)" )
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        if ["protonmail", "mailto"].contains(urlComponents.scheme) || "mailto".caseInsensitiveCompare(urlComponents.scheme ?? "") == .orderedSame {
            var path = url.absoluteString
            if urlComponents.scheme == "protonmail" {
                path = path.preg_replace("protonmail://", replaceto: "")
            }

            let deeplink = DeepLink(String(describing: MailboxViewController.self), sender: Message.Location.inbox.rawValue)
            deeplink.append(DeepLink.Node(name: "toMailboxSegue", value: Message.Location.inbox))
            deeplink.append(DeepLink.Node(name: "toComposeMailto", value: path))
            self.coordinator.followDeeplink(deeplink)
            return true
        }

        guard urlComponents.host == "signup" else {
            return false
        }
        guard let queryItems = urlComponents.queryItems, let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first else {
            return false
        }

        guard let code = verifyObject.value else {
            return false
        }
        /// TODO::fixme change to deeplink
        let info: [String: String] = ["verifyCode": code]
        let notification = Notification(name: .customUrlSchema,
                                        object: nil,
                                        userInfo: info)
        NotificationCenter.default.post(notification)

        return true
    }

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.sceneDidEnterBackground()" )
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.currentState = .background
        keymaker.updateAutolockCountdownStart()

        let users: UsersManager = sharedServices.get()
        let queueManager: QueueManager = sharedServices.get()

        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask { }
        let delayedCompletion: () -> Void = {
            application.endBackgroundTask(taskID)
            taskID = .invalid
        }

        if users.firstUser != nil {
            queueManager.backgroundFetch(remainingTime: {
                application.backgroundTimeRemaining
            }, notify: {
                delayedCompletion()
            })
        } else {
            delayedCompletion()
        }
        BackgroundTimer.shared.willEnterBackgroundOrTerminate()
    }

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, deprecated in favor of similar method in WindowSceneDelegate" )
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let data = userActivity.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data) {
            self.coordinator.followDeepDeeplinkIfNeeded(deeplink)
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // TODO::here need change to notify composer to save editing draft
        let coreDataService = sharedServices.get(by: CoreDataService.self)

        let rootContext = coreDataService.rootSavingContext
        rootContext.performAndWait {
            _ = rootContext.saveUpstreamIfNeeded()
        }
        BackgroundTimer().willEnterBackgroundOrTerminate()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        self.currentState = .active
        let users: UsersManager = sharedServices.get()
        let queueManager = sharedServices.get(by: QueueManager.self)
        if let user = users.firstUser {
            queueManager.enterForeground()
            user.refreshFeatureFlags()
            user.messageService.purgeOldMessages()
            user.cacheService.cleanOldAttachment()
            user.messageService.updateMessageCount()
        }
    }

    // MARK: Background methods
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // this feature can only work if user did not lock the app
//        let signInManager = SignInManagerProvider()
//        let unlockManager = UnlockManagerProvider()
//        guard signInManager.isSignedIn, unlockManager.isUnlocked else {
//            completionHandler(.noData)
//            return
//        }
//
//        let queueManager = sharedServices.get(by: QueueManager.self)
//        queueManager.backgroundFetch(remainingTime: {
//            application.backgroundTimeRemaining
//        }, notify: {
//            completionHandler(.newData)
//        })
        completionHandler(.noData)
    }

    // MARK: Notification methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let pushService: PushNotificationService = sharedServices.get()
        pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PushUpdater().update(with: userInfo) {
            completionHandler(.newData)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: UIApplication.shared.keyWindow)
            let statusBarFrame = UIApplication.shared.statusBarFrame
            if statusBarFrame.contains(point) {
                self.touchStatusBar()
            }
        }
    }

    func touchStatusBar() {
        let notification = Notification(name: .touchStatusBar, object: nil, userInfo: nil)
        NotificationCenter.default.post(notification)
    }

    // MARK: - Multiwindow iOS 13

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let scene = Scenes.fullApp // TODO: add more scenes
        let config = UISceneConfiguration(name: scene.rawValue, sessionRole: connectingSceneSession.role)
        config.delegateClass = scene.delegateClass
        return config
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        sceneSessions.forEach { session in
            // TODO: check that this discards state restoration for scenes explicitely closed by user
            // up to at least iOS 13.3 beta 2 this does not work properly
            session.stateRestorationActivity = nil
            session.scene?.userActivity = nil
        }
    }

    // MARK: Shortcuts
    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, deprecated in favor of similar method in WindowSceneDelegate" )
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data) {
            self.coordinator.followDeepDeeplinkIfNeeded(deeplink)
        }
        completionHandler(true)
    }
}

extension AppDelegate: UsersManagerDelegate {

}

extension AppDelegate: UnlockManagerDelegate {
    func isUserStored() -> Bool {
        let users = sharedServices.get(by: UsersManager.self)
        if users.hasUserName() || users.hasUsers() {
            return true
        }
        return false
    }

    func isMailboxPasswordStored(forUser uid: String?) -> Bool {
        let users = sharedServices.get(by: UsersManager.self)
        guard let _ = uid else {
            return users.isPasswordStored || users.hasUserName() // || users.isMailboxPasswordStored
        }
        return !(sharedServices.get(by: UsersManager.self).users.last?.mailboxPassword ?? "").isEmpty
    }

    func cleanAll() {
        ///
        sharedServices.get(by: UsersManager.self).clean().cauterize()
        keymaker.wipeMainKey()
        keymaker.mainKeyExists()
    }
}

// MARK: Appearance
extension AppDelegate {
    private var backArrowImage: UIImage? {
        UIImage(named: "back-arrow")?.withRenderingMode(.alwaysTemplate)
    }

    private func configureAppearance() {
        UINavigationBar.appearance().backIndicatorImage = backArrowImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backArrowImage
        if #available(iOS 15.0, *) {
            setupNavigationBarAppearance()
            UITableView.appearance().sectionHeaderTopPadding = .zero
        }
    }

    @available(iOS 15.0, *)
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorProvider.BackgroundNorm
        appearance.shadowColor = .clear
        appearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }
}

// MARK: Launch configuration
extension AppDelegate {
    private func configForWillLaunch() {
        guard self.hasConfigureForWillLaunch == false else { return }
        self.hasConfigureForWillLaunch = true

        sharedServices.get(by: AppCacheService.self).restoreCacheWhenAppStart()

        let usersManager = UsersManager(doh: DoHMail.default, delegate: self)
        let lastUpdatedStore = sharedServices.get(by: LastUpdatedStore.self)
        let messageQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.name)
        let miscQueue = PMPersistentQueue(queueName: PMPersistentQueue.Constant.miscName)
        let queueManager = QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        sharedServices.add(QueueManager.self, for: queueManager)
        sharedServices.add(UnlockManager.self, for: UnlockManager(cacheStatus: userCachedStatus, delegate: self))
        sharedServices.add(UsersManager.self, for: usersManager)
        sharedServices.add(SignInManager.self, for: SignInManager(usersManager: usersManager, lastUpdatedStore: lastUpdatedStore, queueManager: queueManager))
        sharedServices.add(SpringboardShortcutsService.self, for: SpringboardShortcutsService())
        sharedServices.add(StoreKitManagerImpl.self, for: StoreKitManagerImpl())
        sharedServices.add(InternetConnectionStatusProvider.self, for: InternetConnectionStatusProvider())
    }

    private func configForDidLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard self.hasConfigureForDidLaunch == false else { return }
        self.hasConfigureForDidLaunch = true

        #if DEBUG
        if CommandLine.arguments.contains("-disableAnimations") {
            UIView.setAnimationsEnabled(false)
        }
        #endif
        self.configureAnalytics()
        UIApplication.shared.setMinimumBackgroundFetchInterval(300)
        configureAppearance()
        
        //start network notifier
        sharedInternetReachability.startNotifier()
        self.configureLanguage()
        self.configurePushService(launchOptions: launchOptions)
        self.registerKeyMakerNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSignOutNotification(_:)),
                                               name: NSNotification.Name.didSignOut,
                                               object: nil)
        
        if #available(iOS 13.0, *) {
            // multiwindow support managed by UISessionDelegate, not UIApplicationDelegate
        } else {
            self.coordinator.start()
        }

        UIBarButtonItem.enableMenuSwizzle()
        #if DEBUG
        setupUITestsMocks()
        #endif
    }

    private func configureAnalytics() {
        #if DEBUG
            Analytics.shared.setup(isInDebug: true, environment: .production)
        #else
            #if Enterprise
            Analytics.shared.setup(isInDebug: false, environment: .enterprise)
            #else
            Analytics.shared.setup(isInDebug: false, environment: .production)
            #endif
        #endif
    }

    private func configureLanguage() {
        // setup language: iOS 13 allows setting language per-app in Settings.app, so we trust that value
        // we still use LanguageManager because Bundle.main of Share extension will take the value from host application :(
        if #available(iOS 13.0, *),
            let code = Bundle.main.preferredLocalizations.first {
            LanguageManager.saveLanguage(byCode: code)
        }
        //setup language
        LanguageManager.setupCurrentLanguage()
    }

    private func configurePushService(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let pushService : PushNotificationService = sharedServices.get()
        UNUserNotificationCenter.current().delegate = pushService
        pushService.registerForRemoteNotifications()
        pushService.setLaunchOptions(launchOptions)
    }

    private func registerKeyMakerNotification() {
        #if DEBUG
        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.errorObtainingMainKey,
                         object: nil,
                         queue: .main) { notification in
                (notification.userInfo?["error"] as? Error)?.localizedDescription.alertToast()
            }

        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.removedMainKeyFromMemory,
                         object: nil,
                         queue: .main) { notification in
                "Removed main key from memory".alertToastBottom()
            }
        #endif

        NotificationCenter.default
            .addObserver(forName: Keymaker.Const.obtainedMainKey,
                         object: nil,
                         queue: .main) { notification in
                #if DEBUG
                "Obtained main key".alertToastBottom()
                #endif

                if self.currentState != .active {
                    keymaker.updateAutolockCountdownStart()
                }
            }
    }
}

#if DEBUG
extension AppDelegate {
    private func setupUITestsMocks() {
        let environment = ProcessInfo.processInfo.environment
        if let _ = environment["HumanVerificationStubs"] {
            HumanVerificationManager.shared.setupUITestsMocks()
        } else if let _ = environment["ForceUpgradeStubs"] {
            ForceUpgradeManager.shared.setupUITestsMocks()
        }
    }
}
#endif
