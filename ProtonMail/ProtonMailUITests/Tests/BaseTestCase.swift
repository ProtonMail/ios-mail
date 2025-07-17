//
//  BaseTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation
import XCTest
import fusion
import ProtonCoreLog
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsCore
import ProtonCoreTestingToolkitUITestsLogin
import Yams

let apiDomainKey = "MAIL_APP_API_DOMAIN"
let testData = TestData()
var users: [String: User] = [:]
var wasJailDisabled = false

var dynamicDomain: String {
    if let domain = ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"], !domain.isEmpty {
        return domain
    } else {
        return "proton.black"
    }
}
var quarkCommands = Quark().baseUrl("https://\(dynamicDomain)/api").configureTimeouts(request: 120, resource: 120)

/**
 Parent class for all the test classes.
 */
class BaseTestCase: ProtonCoreBaseTestCase {

    var _launchArguments = [
        "-clear_all_preference", "YES",
        "-disableAnimations",
        "-skipTour",
        "-toolbarSpotlightOff",
        "-uiTests",
        "-com.apple.CoreData.ConcurrencyDebug", "1",
        "-AppleLanguages", "(en)",
        "-disableInAppFeedbackPromptAutoShow"
    ]
    private let loginRobot = LoginRobot()


    func terminateApp() {
        app.terminate()
    }

    /// Runs only once per test run.
    override class func setUp() {
        super.setUp()
        getTestUsersFromYamlFiles()

        do {
            try quarkCommands.systemEnv(variable: "PROHIBIT_DEPRECATED_DEV_CLIENT_ENV", value: "0")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    override func setUp() {
        bundleIdentifier = "pm.ProtonMailUITests"
        beforeSetUp(bundleIdentifier: "pm.ProtonMailUITests", launchArguments: _launchArguments, launchEnvironment: [apiDomainKey: dynamicDomain!])
        super.setUp()
        PMLog.info("UI TEST runs on: " + "https://\(dynamicDomain!)")
        handleInterruption()
        disableJail()
    }

    override func tearDown() {
        terminateApp()
        super.tearDown()
    }

    func handleInterruption() {
        let labels = [
            LocalString._skip_btn_title,
            "Allow Access to All Photos",
            "Select Photos...",
            "Don’t Allow",
            "Keep Current Selection",
            LocalString._send_anyway,
            LocalString._general_ok_action,
            LocalString._hide,
            "Not Now",
        ]
        /// Adds UI interruption monitor that queries all buttons and clicks if identifier is in the labels array. It is triggered when system alert interrupts the test execution.
        addUIMonitor(elementQueryToTap: XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons, identifiers: labels)
    }

    fileprivate func login(user: User) {
        loginRobot.loginUser(user)
    }

    private static func getYamlFiles(in folderURL: URL) -> [URL] {
        var files: [URL] = []

        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "user.yml" {
                    files.append(fileURL)
                }
            }
        }

        return files
    }

    private static func getTestUsersFromYamlFiles() {
        var userYamlFiles: [URL]

        guard let testDataURL = Bundle(for: BaseTestCase.self).url(forResource: "TestData", withExtension: nil) else {
            // Handle the case when TestData folder is not found
            return
        }
        userYamlFiles = getYamlFiles(in: testDataURL)

        assert(!userYamlFiles.isEmpty, "Attempted to parse user.yml files from TestData repository but was not able to find any.")

        for file in userYamlFiles {
            do {
                if let data = try String(contentsOf: file).data(using: .utf8) {
                    let user = try YAMLDecoder().decode(User.self, from: data)
                    users[user.name] = user
                }
            } catch {
                print("Error deserializing YAML: \(error.localizedDescription)")
            }
        }
    }

    private func disableJail() {
        if !wasJailDisabled {
            do {
                try quarkCommands.jailUnban()
            }
            catch {
                XCTFail(error.localizedDescription)
            }
            wasJailDisabled = true
        }
    }
}

class FixtureAuthenticatedTestCase: BaseTestCase {

    var scenario: MailScenario = .qaMail001
    var plan: UserPlan { .mailpro2022 }
    var isSubscriptionIncluded: Bool { true }
    var user: User = User(name: "init", password: "init")

    override func setUp() {
        super.setUp()
    }

    func runTestWithScenario(_ actualScenario: MailScenario, testBlock: () -> Void) {
        scenario = actualScenario
        createUserAndLogin()
        testBlock()
    }

    func runTestWithScenarioDoNotLogin(_ actualScenario: MailScenario, testBlock: () -> Void) {
        scenario = actualScenario
        user = createUser()
        testBlock()
    }

    func createUser(scenarioName: String, plan: UserPlan, isEnableEarlyAccess: Bool) -> User {
        var user: User = User(name: "init", password: "init")

        do {
            if scenario.name.starts(with: "qa-mail-web") {
                user = try quarkCommands.createUserWithFixturesLoad(name: scenarioName)

                try quarkCommands.enableSubscription(id: user.id!, plan: plan.rawValue)
                try quarkCommands.enableEarlyAccess(username: user.name)

            } else {
                let users = try quarkCommands.createUserWithiOSFixturesLoad(name: scenarioName)

                for user in users {
                    try quarkCommands.enableSubscription(id: user.id!, plan: plan.rawValue)
                    try quarkCommands.enableEarlyAccess(username: user.name)
                }
                user = users.first! // currently the first user used only

            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        return user
    }

    private func createUserAndLogin() {
        user = createUser(scenarioName: scenario.name, plan: plan, isEnableEarlyAccess: true)
        login(user: user)
    }

    @discardableResult
    func createUser() -> User {
        return createUser(scenarioName: scenario.name, plan: plan, isEnableEarlyAccess: true)
    }

    override func tearDown() {
        defer { super.tearDown() }
        guard let id = user.id else { return }
        do {
            try quarkCommands.deleteUser(id: id)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
}
