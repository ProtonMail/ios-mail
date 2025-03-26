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
import ProtonCoreCrypto
import ProtonCoreCryptoGoImplementation
import ProtonCoreDataModel
import ProtonCoreDoh
@preconcurrency import ProtonCoreFeatureFlags
import ProtonCoreKeymaker
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCorePayments
@preconcurrency import ProtonCoreServices
import ProtonCoreTelemetry
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import SideMenuSwift
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder {
    lazy var coordinator: WindowsCoordinator = {
        WindowsCoordinator(dependencies: dependencies)
    }()
    private var currentState: UIApplication.State = .active

    // TODO: make private
    let dependencies = GlobalContainer()

    private var springboardShortcutsService: SpringboardShortcutsService!

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
        setupLogLocation()

        let appVersion = Bundle.main.appVersion
        let message = "\(#function) data available: \(UIApplication.shared.isProtectedDataAvailable) | \(appVersion)"
        SystemLogger.log(message: message, category: .appLifeCycle)

        cleanKeychainInCaseOfAppReinstall()
        let appCache = AppCacheService(dependencies: dependencies)

        do {
            try appCache.restoreCacheWhenAppStart()
        } catch {
            SystemLogger.log(error: error)
        }

        let coreKeyMaker = dependencies.keyMaker

        if ProcessInfo.isRunningUnitTests {
            // swiftlint:disable:next force_try
            try! CoreDataStore.shared.initialize()

            coreKeyMaker.wipeMainKey()
            coreKeyMaker.activate(NoneProtection(keychain: dependencies.keychain)) { _ in }
        }

        let unlockManager = dependencies.unlockManager
        unlockManager.delegate = self

        springboardShortcutsService = .init(dependencies: dependencies)

#if DEBUG
        if !ProcessInfo.isRunningUnitTests {
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
        PMAPIService.setupTrustIfNeeded()
        configureCoreLogger()
        configureCrypto()
        configureCoreObservability()
        configureAppearance()
        fetchUnauthFeatureFlags()
        configureCoreTelemetry()
        DFSSetting.enableDFS = true
        DFSSetting.limitToXXXLarge = true
        /// configurePushService needs to be called in didFinishLaunchingWithOptions to make push
        /// notification actions work. This is because the app could be inactive when an action is triggered
        /// and `didFinishLaunchingWithOptions` will be called, but other functions
        /// like `applicationWillEnterForeground` won't.
        self.configurePushService(launchOptions: launchOptions)
        self.registerKeyMakerNotification()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didSignOutNotification),
                                               name: .didSignOutLastAccount,
                                               object: nil)

        dependencies.backgroundTaskHelper.registerBackgroundTask(task: .eventLoop)

        UIBarButtonItem.enableMenuSwizzle()
#if DEBUG
        setupUITestsMocks()
#endif
        UserObjectsPersistence.shared.cleanAll()
        return true
    }

    @objc fileprivate func didSignOutNotification() {
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

    @available(iOS, deprecated: 13, message: "This method will not get called on iOS 13, move the code to WindowSceneDelegate.sceneDidEnterBackground()" )
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.currentState = .background

        startAutoLockCountDownIfNeeded()

        dependencies.backgroundTaskHelper.scheduleBackgroundRefreshIfNeeded(task: .eventLoop)

        var taskID = UIBackgroundTaskIdentifier(rawValue: 0)
        taskID = application.beginBackgroundTask { }
        let delayedCompletion: () -> Void = {
            application.endBackgroundTask(taskID)
            taskID = .invalid
        }

        if let user = dependencies.usersManager.firstUser {
            user.cacheService.cleanOldAttachment()

            dependencies.queueManager.backgroundFetch(remainingTime: {
                application.backgroundTimeRemaining
            }, notify: {
                delayedCompletion()
            })
        } else {
            delayedCompletion()
        }
        BackgroundTimer.shared.willEnterBackgroundOrTerminate()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SystemLogger.log(message: "application will terminate", category: .appLifeCycle)
        BackgroundTimer().willEnterBackgroundOrTerminate()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Crypto.freeGolangMem()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        dependencies.pushService.registerIfAuthorized()
        self.currentState = .active
        if let user = dependencies.usersManager.firstUser {
            dependencies.queueManager.enterForeground()
            user.refreshFeatureFlags()
            user.blockedSenderCacheUpdater.requestUpdate()
            importDeviceContactsIfNeeded(user: user)
            user.sendLocalSettingsTelemetryHeartbeat()
        }
    }

    // MARK: Notification methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if ProcessInfo.isRunningUnitTests {
            return
        }
        dependencies.pushService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.stringFromToken())
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        dependencies.pushUpdater.update(with: userInfo)
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

    private func startAutoLockCountDownIfNeeded() {
        let coreKeyMaker = dependencies.keyMaker
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

    private func importDeviceContactsIfNeeded(user: UserManager) {
        if user.container.autoImportContactsFeature.shouldImportContacts {
            guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
                user.container.autoImportContactsFeature.disableSettingAndDeleteQueueForUser()
                return
            }

            let params = ImportDeviceContacts.Params(
                userKeys: user.userInfo.userKeys,
                mailboxPassphrase: user.mailboxPassword
            )
            user.container.importDeviceContacts.execute(params: params)
        }
    }
}

extension AppDelegate: UnlockManagerDelegate {
    func isUserStored() -> Bool {
        let users = dependencies.usersManager
        return users.hasUsers()
    }

    func isMailboxPasswordStoredForActiveUser() -> Bool {
        return !(dependencies.usersManager.users.last?.mailboxPassword.value ?? "").isEmpty
    }

    func cleanAll(completion: @escaping () -> Void) {
        Breadcrumbs.shared.add(message: "AppDelegate.cleanAll called", to: .randomLogout)
        dependencies.usersManager.clean().ensure {
            completion()
        }.cauterize()
    }

    func setupCoreData() throws {
        try CoreDataStore.shared.initialize()
    }

    func loadUserDataAfterUnlock() {
        dependencies.launchService.loadUserDataAfterUnlock()
    }

    private func setupLogLocation() {
        // Delete old log in the app container
        if let originalLogFile = PMLog.logFile {
            if FileManager.default.fileExists(atPath: originalLogFile.path) {
                do {
                    try FileManager.default.removeItem(at: originalLogFile)
                } catch {
                    PMAssertionFailure(error)
                }
            }
        }
        // Set the log file location to app group
        let directory = FileManager.default.appGroupsDirectoryURL
        PMLog.logsDirectory = directory
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
        setupNavigationBarAppearance()
        UITableView.appearance().sectionHeaderTopPadding = .zero
        UIStackView.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).spacing = -4
    }

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
    private func configureCoreLogger() {
        let environment: String
        switch BackendConfiguration.shared.environment {
        case .black, .blackPayment: environment = "black"
        case .custom(let custom): environment = custom
        default: environment = "production"
        }
        //PMLog.setEnvironment(environment: environment)
    }

    private func configureCrypto() {
        Crypto().initializeGoCryptoWithDefaultConfiguration()
    }

    private func configureCoreObservability() {
        ObservabilityEnv.current.setupWorld(requestPerformer: PMAPIService.unauthorized(dependencies: dependencies))
    }

    private func configureCoreTelemetry() {
        ProtonCoreTelemetry.TelemetryService.shared.setApiService(apiService: PMAPIService.unauthorized(dependencies: dependencies))
        ProtonCoreTelemetry.TelemetryService.shared.setTelemetryEnabled(dependencies.usersManager.firstUser?.hasTelemetryEnabled ?? true)
    }

    private func fetchUnauthFeatureFlags() {
        FeatureFlagsRepository.shared.setApiService(PMAPIService.unauthorized(dependencies: dependencies))

        FeatureFlagsRepository.shared.setFlagOverride(CoreFeatureFlagType.dynamicPlan, true)
        //FeatureFlagsRepository.shared.setFlagOverride(CoreFeatureFlagType.fidoKeys, true)

        // TODO: This is a wayward fetch that will complete at an arbitrary point in time during app launch,
        // possibly resulting in an inconsistent behavior.
        // Consider placing it in LaunchService once it's ready.
        Task {
            try await FeatureFlagsRepository.shared.fetchFlags()
        }
    }

    private func configurePushService(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let pushService = dependencies.pushService
        UNUserNotificationCenter.current().delegate = pushService
        pushService.registerIfAuthorized()
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
                    self.dependencies.keyMaker.updateAutolockCountdownStart()
                }
            }
    }

    /// If this is the first app launch, we clean the keychain to avoid state inconsistencies from a previous installation
    private func cleanKeychainInCaseOfAppReinstall() {
        let isFirstLaunch = dependencies.userCachedStatus.initialUserLoggedInVersion == nil
        if isFirstLaunch {
            dependencies.keychain.removeEverything()
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
