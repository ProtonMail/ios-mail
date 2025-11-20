// Copyright (c) 2025 Proton Technologies AG
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
import NIO
import XCTest

extension XCUIApplication {

    func setAppLaunchArguments() -> XCUIApplication {
        self.launchArguments += ["-uiTesting", "true"]
        self.launchArguments += ["-AppleLanguages", "[\"en\"]"]
        self.launchArguments += ["-AppleLocale", "en_US"]
        return self
    }
}

final class LoadingInboxTests: XCTestCase {

    private let app = XCUIApplication().setAppLaunchArguments()

    private lazy var measurementContext = MeasurementContext(MeasurementConfig.self)

    override func setUp() {
        super.setUp()
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }

    func testLoadingInbox() {
        MeasurementConfig
            .setBundle(Bundle(identifier: "ch.protonmail.protonmail")!)
            .setLokiEndpoint(getTestConfigValue(forKey: "LOKI_ENDPOINT"))
            .setEnvironment("black")
            .setLokiCertificate("certificate_ios_sdk")
            .setLokiCertificatePassphrase(getTestConfigValue(forKey: "CERTIFICATE_IOS_SDK_PASSPHRASE"))

        let measurementProfile = measurementContext.setWorkflow("ios_functional_load_time", forTest: self.name)
        measurementProfile
            .addMeasurement(DurationMeasurement())
            .setServiceLevelIndicator("inbox_load_time")

        WelcomeRobot { $0.tapSignIn() }
        SignInRobot {
            $0.typeUsername(getTestConfigValue(forKey: "ET_USER"))
            $0.typePassword(getTestConfigValue(forKey: "ET_USER_PWD"))
        }

        /// Measure inbox load time in measure block below
        measurementProfile.measure {
            SignInRobot { $0.tapSignIn() }
            MailboxRobot { $0.verifyShown() }
        }

        /// Sign out user
        MailboxRobot { $0.openSidebarMenu() }
        SidebarMenuRobot { $0.signOutProperly() }
        WelcomeRobot { $0.verifyIsDisplayed() }
    }
}
