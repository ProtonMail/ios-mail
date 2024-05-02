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

import Foundation
import XCTest

struct UITestNavigator {
    let environment: UITestsEnvironment
    let loginType: UITestLoginType

    func navigateTo(
        _ destination: UITestDestination,
        performAppLaunch: Bool = true,
        performLogin: Bool = true
    ) {
        if performAppLaunch {
            launchApp(environment: environment)
        }

        if performLogin {
            login(loginType)
        }

        switch destination {
        case .inbox:
            // Inbox is the landing label, nothing to do.
            break
        }
    }

    private func login(_ loginType: UITestLoginType) {
        switch loginType {
        case .loggedIn(let user):
            SignInRobot {
                $0.typeUsername(user.username)
                $0.typePassword(user.password)
                $0.tapSignIn()
            }
            break
        case .loggedOut:
            XCTFail("Unable to perform login with a loggedOut loginType")
            return
        }
    }

    private func launchApp(environment: UITestsEnvironment) {
        let app = XCUIApplication()

        app.launchArguments += ["-uiTesting", "true"]
        app.launchArguments += ["-forceCleanState", "true"]

        if let serverPort = environment.socketAddress.port {
            app.launchArguments += ["-mockServerPort", "\(serverPort)"]
        }
        else {
            print("No mock server running, skipping custom launch arguments.")
        }

        app.launch()
    }
}
