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
import XCTest
import NIO

final class LoadingConversationTest: XCTestCase {

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

    func testOpenMessage() {
        MeasurementConfig
            .setBundle(Bundle(identifier: "ch.protonmail.protonmail")!)
            .setLokiEndpoint(getTestConfigValue(forKey: "LOKI_ENDPOINT"))
            .setEnvironment("pink")
            .setLokiCertificate("certificate_ios_sdk")
            .setLokiCertificatePassphrase(getTestConfigValue(forKey: "CERTIFICATE_IOS_SDK_PASSPHRASE"))

        let measurementProfile = measurementContext.setWorkflow("ios_functional_load_time", forTest: self.name)
        measurementProfile
            .addMeasurement(DurationMeasurement())
            .setServiceLevelIndicator("message_load_time")

        WelcomeRobot {
            $0.tapSignIn()
        }
        SignInRobot {
            $0.typeUsername(getTestConfigValue(forKey: "ET_USER"))
            $0.typePassword(getTestConfigValue(forKey: "ET_USER_PWD"))
            $0.tapSignIn()
        }

        let messageSubject = "Get started with Proton Mail and increase your storage for free"

        MailboxRobot {
            $0.verifyShown()
            $0.waitMessageBySubject(subject: messageSubject)
        }
        /// Measure inbox load time in measure block below
        measurementProfile.measure {
            MailboxRobot {
                $0.clickMessageBySubject(subject: messageSubject)
            }
            ConversationDetailRobot {
                $0.waitForLoaderToDisappear()
            }
        }

        ConversationDetailRobot {
            $0.tapBackChevronButton()
        }
        MailboxRobot {
            $0.openSidebarMenu()
        }
        SidebarMenuRobot {
            $0.signOutProperly()
        }
        WelcomeRobot {
            $0.verifyIsDisplayed()
        }
    }
}
