//
//  AppDelegate.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import BackgroundTasks
import Intents
import LifetimeTracker
import ProtonCore_Crypto
import ProtonCore_CryptoGoImplementation
import ProtonCore_DataModel
import ProtonCore_Doh
import ProtonCore_FeatureSwitch
import ProtonCore_Keymaker
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Observability
import ProtonCore_Payments
import ProtonCore_Services
import ProtonCore_UIFoundations
import ProtonMailAnalytics
import SideMenuSwift
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder {
    lazy var coordinator: WindowsCoordinator = WindowsCoordinator(factory: sharedServices)
    private var currentState: UIApplication.State = .active
    private var purgeOldMessages: PurgeOldMessagesUseCase?

    // TODO: make private
    let dependencies = GlobalContainer()

    override init() {
        injectDefaultCryptoImplementation()
        super.init()
    }
}

// MARK: - consider move this to coordinator
extension AppDelegate {
    func onLogout() {
            let sessions = Array(UIApplication.shared.openSessions)
            let oneToStay = sessions.first(where: { $0.scene?.delegate as? WindowSceneDelegate != nil })
            (oneToStay?.scene?.delegate as? WindowSceneDelegate)?.coordinator.go(dest: .signInWindow(.form))

            for session in sessions where session != oneToStay {
                UIApplication.shared.requestSceneSessionDestruction(session, options: nil) { _ in }
            }
    }
}

extension AppDelegate: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        let currentWindow: UIWindow? = {
                let session = UIApplication.shared.openSessions.first { $0.scene?.activationState == UIScene.ActivationState.foregroundActive }
                let scene = session?.scene as? UIWindowScene
                let window = scene?.windows.first
                return window
        }()

        guard let top = currentWindow?.topmostViewController(), !(top is UIAlertController) else { return }
        top.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UIApplicationDelegate
extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let appVersion = Bundle.main.appVersion
        let message = "\(#function) data available: \(UIApplication.shared.isProtectedDataAvailable) | \(appVersion)"
        SystemLogger.log(message: message, category: .appLifeCycle)
        sharedServices.add(UserCachedStatus.self, for: userCachedStatus)

        let coreKeyMaker = dependencies.keyMaker
        sharedServices.add(Keymaker.self, for: coreKeyMaker)
        sharedServices.add(KeyMakerProtocol.self, for: coreKeyMaker)

        if ProcessInfo.isRunningUnitTests {
            coreKeyMaker.wipeMainKey()
            coreKeyMaker.activate(NoneProtection()) { _ in }
        }

        let usersManager = dependencies.usersManager
        let queueManager = dependencies.queueManager
        sharedServices.add(QueueManager.self, for: queueManager)
        sharedServices.add(UnlockManager.self, for: UnlockManager(
            cacheStatus: coreKeyMaker,
            delegate: self,
            keyMaker: coreKeyMaker,
            pinFailedCountCache: userCachedStatus
        ))
        sharedServices.add(UsersManager.self, for: usersManager)
        let dependencies = PushNotificationService.Dependencies(lockCacheStatus: coreKeyMaker)
        sharedServices.add(PushNotificationService.self, for: PushNotificationService(dependencies: dependencies))
        let updateSwipeActionUseCase = UpdateSwipeActionDuringLogin(dependencies: self.dependencies)
        sharedServices.add(SignInManager.self, for: SignInManager(usersManager: usersManager,
                                                                  contactCacheStatus: userCachedStatus,
                                                                  queueHandlerRegister: queueManager,
                                                                  updateSwipeActionUseCase: updateSwipeActionUseCase))
        sharedServices.add(SpringboardShortcutsService.self, for: SpringboardShortcutsService())
        sharedServices.add(StoreKitManagerImpl.self, for: StoreKitManagerImpl())
        sharedServices.add(NotificationCenter.self, for: NotificationCenter.default)

#if DEBUG
        if ProcessInfo.isRunningUnitTests {
            sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
        } else {
            let lifetimeTrackerIntegration = LifetimeTrackerDashboardIntegration(
                visibility: .visibleWithIssuesDetected,
                style: .circular
            )
            LifetimeTracker.setup(onUpdate: lifetimeTrackerIntegration.refreshUI)
        }
#endif

        SecureTemporaryFile.cleanUpResidualFiles()

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SystemLogger.log(message: #function, category: .appLifeCycle)
        #if DEBUG
        if ProcessInfo.isRunningUITests {
            UIView.setAnimationsEnabled(false)
        }
        #endif
        configureCrypto()
        configureCoreFeatureFlags(launchArguments: ProcessInfo.launchArguments)
        configureCoreObservability()
        configureAnalytics()
        configureAppearance()
        DFSSetting.enableDFS = true
        DFSSetting.limitToXXXLarge = true
        self.configureLanguage()
        /// configurePushService needs to be called in didFinishLaunchingWithOptions to make push
        /// notification actions work. This is because the app could be inactive when an action is triggered
        /// and `didFinishLaunchingWithOptions` will be called, but other functions
        /// like `applicationWillEnterForeground` won't.
        self.configurePushService(launchOptions: launchOptions)
        self.registerKeyMakerNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSignOutNotification(_:)),
                                               name: .didSignOutLastAccount,
                                               object: nil)
        coordinator.delegate = self

        UIBarButtonItem.enableMenuSwizzle()
        #if DEBUG
        setupUITestsMocks()
        #endif
        return true
    }

    @objc fileprivate func didSignOutNotification(_: Notification) {
        self.onLogout()
    }

    func application(
          _ application: UIApplication,
          supportedInterfaceOrientationsFor window: UIWindow?
      ) -> UIInterfaceOrientationMask {
          let viewController = window?.rootViewController
          if UIDevice.current.userInterfaceIdiom == .pad || viewController == nil {
              return UIInterfaceOrientationMask.all
          }
          if viewController as? CoordinatorKeepingViewController<LockCoordinator> != nil {
              return .portrait
          }
          return .all
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
            self.coordinator.followDeepLink(deeplink)
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

        startAutoLockCountDownIfNeeded()

        let users: UsersManager = sharedServices.get()
        let queueManager: QueueManager = sharedServices.get()

        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask { }
        let delayedCompletion: () -> Void = {
            application.endBackgroundTask(taskID)
            taskID = .invalid
        }

        if let user = users.firstUser {
            let coreDataService: CoreDataService = sharedServices.get()
            self.purgeOldMessages = PurgeOldMessages(user: user,
                                                     coreDataService: coreDataService)
            self.purgeOldMessages?.execute(
                params: (),
                callback: { [weak self] _ in
                    self?.purgeOldMessages = nil
                }
            )
            user.cacheService.cleanOldAttachment()
            user.messageService.updateMessageCount()

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
            self.coordinator.followDeepDeepLinkIfNeeded(deeplink)
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        BackgroundTimer().willEnterBackgroundOrTerminate()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Crypto.freeGolangMem()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        let pushService: PushNotificationService = sharedServices.get()
        pushService.registerIfAuthorized()
        self.currentState = .active
        let users: UsersManager = sharedServices.get()
        let queueManager = sharedServices.get(by: QueueManager.self)
        if let user = users.firstUser {
            queueManager.enterForeground()
            user.refreshFeatureFlags()

            if UserInfo.isBlockSenderEnabled {
                user.blockedSenderCacheUpdater.requestUpdate()
            }
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
        if ProcessInfo.isRunningUnitTests {
            return
        }
        let pushService: PushNotificationService = sharedServices.get()
        pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        PushUpdater().update(with: userInfo)
        completionHandler(.newData)
    }

    // MARK: - Multiwindow iOS 13

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let scene = Scenes.fullApp // TODO: add more scenes
        let config = UISceneConfiguration(name: scene.rawValue, sessionRole: connectingSceneSession.role)
        config.delegateClass = scene.delegateClass
        return config
    }

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
            self.coordinator.followDeepDeepLinkIfNeeded(deeplink)
        }
        completionHandler(true)
    }

    private func startAutoLockCountDownIfNeeded() {
        let coreKeyMaker: KeyMakerProtocol = sharedServices.get()
        // When the app is launched without a lock set, the lock counter will immediately remove the mainKey, which triggers the app to display the lock screen.
        // However, this behavior is not necessary if there is no lock set.
        // We should only start the countdown when a lock has been set.
        guard coreKeyMaker.isProtectorActive(PinProtection.self) ||
                coreKeyMaker.isProtectorActive(BioProtection.self)
        else {
            return
        }
        coreKeyMaker.updateAutolockCountdownStart()
    }
}

extension AppDelegate: UnlockManagerDelegate, WindowsCoordinatorDelegate {
    func currentApplicationState() -> UIApplication.State {
        UIApplication.shared.applicationState
    }

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
        return !(sharedServices.get(by: UsersManager.self).users.last?.mailboxPassword.value ?? "").isEmpty
    }

    func cleanAll(completion: @escaping () -> Void) {
        Breadcrumbs.shared.add(message: "AppDelegate.cleanAll called", to: .randomLogout)
        sharedServices.get(by: UsersManager.self).clean().ensure {
            let coreKeyMaker: KeyMakerProtocol = sharedServices.get()
            coreKeyMaker.wipeMainKey()
            _ = coreKeyMaker.mainKeyExists()
            completion()
        }.cauterize()
    }

    func setupCoreData() {
        do {
            try CoreDataStore.shared.initialize()
        } catch {
            fatalError("\(error)")
        }

        sharedServices.add(CoreDataContextProviderProtocol.self, for: CoreDataService.shared)
        sharedServices.add(CoreDataService.self, for: CoreDataService.shared)
        let lastUpdatedStore = LastUpdatedStore(contextProvider: CoreDataService.shared)
        sharedServices.add(LastUpdatedStore.self, for: lastUpdatedStore)
        sharedServices.add(LastUpdatedStoreProtocol.self, for: lastUpdatedStore)
    }

    func loadUserDataAfterUnlock() {
        let usersManager = sharedServices.get(by: UsersManager.self)
        usersManager.run()
        usersManager.tryRestore()

        #if !APP_EXTENSION
        sharedServices.get(by: UsersManager.self).users.forEach {
            $0.messageService.injectTransientValuesIntoMessages()
        }
        if let primaryUser = usersManager.firstUser {
            primaryUser.payments.storeKitManager.retryProcessingAllPendingTransactions(finishHandler: nil)
        }
        #endif
    }
}

// MARK: Appearance
extension AppDelegate {
    private var backArrowImage: UIImage {
        IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
    }

    private func configureAppearance() {
        UINavigationBar.appearance().backIndicatorImage = IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = IconProvider.arrowLeft.withRenderingMode(.alwaysTemplate)
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

    private func configureAnalytics() {
#if Enterprise
    #if DEBUG
        Analytics.shared.setup(isInDebug: true, environment: .enterprise)
    #else
        Analytics.shared.setup(isInDebug: false, environment: .enterprise)
    #endif
#else
    #if DEBUG
        Analytics.shared.setup(isInDebug: true, environment: .production)
    #else
        Analytics.shared.setup(isInDebug: false, environment: .production)
    #endif
#endif

        if !PMLog.isEnabled {
            /**
             We disable logs for builds that are distributed through the AppStore
             to avoid high number of disk write operations.
             */
            PMLog.logsDirectory = nil
        }
    }

    private func configureCrypto() {
        Crypto().initializeGoCryptoWithDefaultConfiguration()
    }

    private func configureCoreFeatureFlags(launchArguments: [String]) {
        FeatureFactory.shared.enable(&.observability)

        FeatureFactory.shared.enable(&.externalSignup)
        FeatureFactory.shared.enable(&.externalAccountConversion)

        guard !launchArguments.contains("-testNoUnauthSessions") else { return }

        FeatureFactory.shared.enable(&.unauthSession)

        #if DEBUG
        guard launchArguments.contains("-testUnauthSessionsWithHeader") else { return }
        // this is only a test flag used before backend whitelists the app version
        FeatureFactory.shared.enable(&.enforceUnauthSessionStrictVerificationOnBackend)
        #endif
    }

    private func configureCoreObservability() {
        ObservabilityEnv.current.setupWorld(requestPerformer: PMAPIService.unauthorized)
    }

    private func configureLanguage() {
        LanguageManager().storePreferredLanguageToBeUsedByExtensions()
    }

    private func configurePushService(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let pushService: PushNotificationService = sharedServices.get()
        UNUserNotificationCenter.current().delegate = pushService
        pushService.registerForRemoteNotifications()
        pushService.setNotificationFrom(launchOptions: launchOptions)
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
                    let coreKeyMaker: KeyMakerProtocol = sharedServices.get()
                    coreKeyMaker.updateAutolockCountdownStart()
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
