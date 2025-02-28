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

final class AppLifeCycle: NSObject, @unchecked Sendable {
    static let shared = AppLifeCycle()

    private var applicationServices = ApplicationServices()
}

// MARK: App Delegate

extension AppLifeCycle: UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        AppLogger.log(message: "\(#function) | \(Bundle.main.appVersion)", category: .appLifeCycle)

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

    func allScenesDidBecomeActive() {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.becomeActive()
    }

    func allScenesDidEnterBackground() {
        AppLogger.log(message: "\(#function)", category: .appLifeCycle)
        applicationServices.enterBackground()
    }
}


// MARK: Private

extension AppLifeCycle {

    @MainActor
    private func applicationServicesInitialisation() {
        let testService = TestService.shared
        let appContext = AppContext.shared
        let appIconBadgeService = AppIconBadgeService(appContext: appContext)
        let emailsPrefetchingNotifier = EmailsPrefetchingNotifier.shared
        let executePendingActionsBackgroundTaskService = ExecutePendingActionsBackgroundTaskService()
        let notificationAuthorizationService = NotificationAuthorizationService(
            remoteNotificationRegistrar: UIApplication.shared
        )
        // FIXME: - Create `BackgroundTransitionActionsExecutor` here
//        let backgroundTransitionActionsExecutor = BackgroundTransitionActionsExecutor_v1(
//            userSession: { appContext.sessionState.userSession },
//            backgroundTransitionTaskScheduler: UIApplication.shared
//        )

        let eventLoop = EventLoopService(appContext: appContext, eventLoopProvider: appContext)

        applicationServices = .init(
            setUpServices: [
                testService,
                appContext,
                notificationAuthorizationService,
                executePendingActionsBackgroundTaskService
            ],
            becomeActiveServices: [eventLoop, emailsPrefetchingNotifier],
            enterBackgroundServices: [appIconBadgeService, eventLoop], // FIXME: - Add `BackgroundTransitionActionsExecutor` here
            terminateServices: []
        )
    }
}
