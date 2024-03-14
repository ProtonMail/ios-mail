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

import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let appDelegateManager = AppDelegateWrapper()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return appDelegateManager.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

import proton_mail_uniffi

struct AppDelegateWrapper {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {

        do {
            AppLogger.log(message: "\(#function) | \(Bundle.main.appVersion)", category: .appLifeCycle)

            try dependencies.appContext.start()
            return true

        } catch {
            AppLogger.log(error: error, category: .appLifeCycle)
            return false
        }
    }
}

extension AppDelegateWrapper {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
