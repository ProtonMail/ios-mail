// Copyright (c) 2023. Proton Technologies AG
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

import XCTest
import fusion
import iosMonkey
import ProtonCore_Environment
import ProtonCore_QuarkCommands
import ProtonCore_TestingToolkit


@available(iOS 15.0, *)
class MonkeyTests : BaseMonkey, QuarkTestable  {

    private lazy var quarkCommands = QuarkCommands(doh: env.doh)
    private var env: Environment = .black
    private var user: User?
    private var scenario: MailScenario { .qaMail006 }
    private var isSubscriptionIncluded: Bool { true }
    private let apiDomainKey = "MAIL_APP_API_DOMAIN"

    override func setUp() async throws {
        try await super.setUp()

        await setupTest()
        let user = try await createUserWithFixturesLoad(domain: dynamicDomain!, plan: UserPlan.mailpro2022, scenario: scenario, isEnableEarlyAccess: false)
        self.user = user
    }

    override func tearDown() async throws {
        await terminateApp()
        try await deleteUser(domain: dynamicDomain!, user)
        try await super.tearDown()
    }

    @MainActor
    func terminateApp() {
        app.terminate()
    }

    @MainActor
    func setupTest() {
        app.launch()

        env = Environment.custom(dynamicDomain!)
        quarkCommands = QuarkCommands(doh: env.doh)
    }

    override var app: XCUIApplication { get {
        let launchArguments = ["-clear_all_preference", "YES", "-uiTests", "-skipTour"]
        let app =  XCUIApplication()

        app.launchEnvironment[apiDomainKey] = dynamicDomain!
        launchArguments.forEach { app.launchArguments.append($0) }

        return app }
    }
    override var stack: ScreenshotStack { ScreenshotStack(size: 10) }
    override var numberOfSteps: Int {
        var numberOfSteps: Int = 1000
        if let numberOfStepsArgument = ProcessInfo.processInfo.environment["MONKEY_NUMBER_OF_STEPS"], let overriddenNumberOfSteps = Int(numberOfStepsArgument) {
            numberOfSteps = overriddenNumberOfSteps
        }

        return numberOfSteps
    }
    override var screenshotOutputDirectory: String { ProcessInfo.processInfo.environment["MONKEY_SCREENSHOT_OUTPUT_DIRECTORY"] ?? "" }


    func testMonkey() {

        LoginRobot()
            .loginUser(user!)

        randomTouches()
    }
}
