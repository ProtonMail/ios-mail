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

struct UITestNavigator: ApplicationHolder {
    let environment: UITestEnvironment
    let loginType: UITestLoginType

    func navigateTo(
        _ destination: UITestDestination,
        performAppLaunch: Bool = true,
        performLogin: Bool = true,
        skipOnboarding: Bool = true
    ) {
        if performAppLaunch {
            launchApp(environment: environment)
        }

        if performLogin {
            login(loginType)
        }

        MailboxRobot { $0.verifyShown() }

        if (skipOnboarding) {
            dismissOnboarding()
        }

        switch destination {
        case .inbox:
            break
        case .trash:
            MailboxRobot { $0.openSidebarMenu() }
            SidebarMenuRobot { $0.openTrash() }
        case .archive:
            MailboxRobot { $0.openSidebarMenu() }
            SidebarMenuRobot { $0.openArchive() }
        case .sent:
            MailboxRobot { $0.openSidebarMenu() }
            SidebarMenuRobot { $0.openSent() }
        case .spam:
            MailboxRobot { $0.openSidebarMenu() }
            SidebarMenuRobot { $0.openSpam() }
        case .subscription:
            MailboxRobot { $0.openSidebarMenu() }
            SidebarMenuRobot { $0.openSubscription() }
        }
    }

    private func login(_ loginType: UITestLoginType) {
        switch loginType {
        case .loggedIn(let user):
            WelcomeRobot {
                $0.tapSignIn()
            }
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

    private func launchApp(environment: UITestEnvironment) {
        let appWithLaunchArguments = setAppLaunchArguments(
            app: application,
            environment: environment
        )
        appWithLaunchArguments.launch()
    }

    private func dismissOnboarding() {
        OnboardingRobot { $0.dismissIfDisplayed() }
    }

    private func setAppLaunchArguments(
        app: XCUIApplication,
        environment: UITestEnvironment
    ) -> XCUIApplication {
        app.launchArguments += ["-uiTesting", "true"]
        app.launchArguments += ["-forceCleanState", "true"]
        app.launchArguments += ["-AppleLanguages", "[\"en\"]"]
        app.launchArguments += ["-AppleLocale", "en_US"]

        if let serverPort = environment.mockServerPort {
            app.launchArguments += ["-DYNAMIC_DOMAIN", "http://localhost:\(serverPort)"]
        }

        return app
    }
}

extension UITestEnvironment {
    fileprivate var mockServerPort: Int? {
        return (self as? UITestMockedEnvironment)?.socketAddress?.port
    }
}
