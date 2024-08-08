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
import ProtonCoreEnvironment
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsLogin

class MonkeyTests : BaseMonkey  {

    private var scenario: MailScenario { .qaMail006 }
    private let apiDomainKey = "MAIL_APP_API_DOMAIN"
    private var plan: UserPlan = .mail2022
    private var user: User = User(name: "init", password: "init")
    private lazy var quarkCommands = Quark().baseUrl("https://\(dynamicDomain)/api").configureTimeouts(request: 120, resource: 120)

    override func setUp() {
        super.setUp()
        setupTest()
        do {
            user = try quarkCommands.createUserWithFixturesLoad(name: scenario.name)

            try quarkCommands.enableSubscription(id: Int(user.id!), plan: plan.rawValue)
            try quarkCommands.enableEarlyAccess(username: user.name)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    override func tearDown() {
        do {
            try quarkCommands.deleteUser(id: user.id!)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
        super.tearDown()
    }

    func terminateApp() {
        app.terminate()
    }

    func setupTest() {
        app.launch()
    }

    override var app: XCUIApplication { get {
        let launchArguments = ["-clear_all_preference", "YES", "-uiTests", "-skipTour"]
        let app =  XCUIApplication()

        app.launchEnvironment[apiDomainKey] = dynamicDomain
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
            .loginUser(user)

        randomTouches()
    }
}
