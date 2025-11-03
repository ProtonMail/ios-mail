// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import InboxCore
import SwiftUI

@MainActor
final class AppLifeCycle: NSObject, @unchecked Sendable {
    static let shared = AppLifeCycle()

    private var applicationServices = ApplicationServices()
}

// MARK: App Delegate

extension AppLifeCycle: UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AppLogger.log(message: "\(#function) | \(AppVersionProvider().fullVersion)", category: .appLifeCycle)

        applicationServicesInitialisation()
        applicationServices.setUp()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.terminate()
    }
}

// MARK: Scene

extension AppLifeCycle {

    func sceneWillEnterForeground() {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.willEnterForeground()
    }

    func sceneWillResignActive() {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.willResignActive()
    }

    func sceneDidEnterBackground() {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.didEnterBackground()
    }

    func scene(_ scene: UIScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        AppLogger.log(message: "\(#function) \(shortcutItem.type)", category: .appLifeCycle)

        guard
            let deepLinkPath = shortcutItem.userInfo?[MailShortcutItem.UserInfoDeepLinkKey] as? String,
            let deepLink = URL(string: deepLinkPath)
        else {
            AppLogger.log(message: "Failed to determine deep link", category: .appLifeCycle, isError: true)
            return false
        }

        AppLogger.log(message: "Opening \(deepLink)", category: .appLifeCycle)
        return await scene.open(deepLink, options: nil)
    }

}

// MARK: Private

extension AppLifeCycle {

    private func applicationServicesInitialisation() {
        let testService = TestService()
        let networkMonitor = NetworkMonitoringService.shared
        let appContext = AppContext.shared
        let appIconBadgeService = AppIconBadgeService(appContext: appContext)
        let legacyMigrationService = LegacyMigrationService.shared
        let recurringBackgroundTaskService = RecurringBackgroundTaskService()
        let notificationAuthorizationService = NotificationAuthorizationService(
            remoteNotificationRegistrar: UIApplication.shared
        )

        let notificationCleanupService = NotificationCleanupService()
        let paymentsService = PaymentsService(appContext: appContext)

        let backgroundTransitionActionsExecutor = BackgroundTransitionActionsExecutor(
            backgroundTransitionTaskScheduler: UIApplication.shared,
            backgroundTaskExecutorProvider: { appContext.mailSession },
            actionQueueStatusProvider: { appContext.sessionState.userSession }
        )

        let foregroundWorkService = ForegroundWorkService(mailSession: { appContext.mailSession })
        let shortcutItemsService = ShortcutItemsService(appContext: appContext)

        let userNotificationCenterDelegate = UserNotificationCenterDelegate(
            sessionStatePublisher: appContext.$sessionState.eraseToAnyPublisher(),
            urlOpener: UIApplication.shared
        )

        let startAutoLockCountdownService = StartAutoLockCountdownService(mailSession: { appContext.mailSession })

        applicationServices = .init(
            setUpServices: [
                testService,
                networkMonitor,
                appContext,
                legacyMigrationService,
                notificationAuthorizationService,
                paymentsService,
                recurringBackgroundTaskService,
                userNotificationCenterDelegate,
            ],
            willEnterForegroundServices: [
                foregroundWorkService,
                backgroundTransitionActionsExecutor,
            ],
            willResignActiveServices: [
                appIconBadgeService,
                notificationCleanupService,
                shortcutItemsService,
            ],
            didEnterBackgroundServices: [
                foregroundWorkService,
                backgroundTransitionActionsExecutor,
                startAutoLockCountdownService,
            ],
            terminateServices: []
        )
    }
}
