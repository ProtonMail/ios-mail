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
@testable import ProtonMail
import ProtonCore_Environment
import ProtonCore_QuarkCommands
import ProtonCore_TestingToolkit
import Yams

let apiDomainKey = "MAIL_APP_API_DOMAIN"
var environmentFileName = "environment"
var credentialsFileName = "credentials"
let credentialsBlackFileName = "credentials_black"
let testData = TestData()
var users: [String: User] = [:]
var wasJailDisabled = false

var dynamicDomain: String {
    ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"] ?? ""
}

/**
 Parent class for all the test classes.
 */
class BaseTestCase: CoreTestCase {
    
    var launchArguments = ["-clear_all_preference", "YES"]
    var humanVerificationStubs = false
    var forceUpgradeStubs = false
    var extAccountNotSupportedStub = false
    var usesBlackCredentialsFile = true
    private let loginRobot = LoginRobot()

    var env: Environment = .black
    lazy var quarkCommands = QuarkCommands(doh: env.doh)
    var quarkCommandTwo = Quark()
    private static var didTryToDisableAutoFillPassword = false


    func terminateApp() {
        app.terminate()
    }

    /// Runs only once per test run.
    override class func setUp() {
        super.setUp()
        if !didTryToDisableAutoFillPassword {
            disableAutoFillPasswords()
            didTryToDisableAutoFillPassword = true
        }
        getTestUsersFromYamlFiles()
    }

    /// Runs before eact test case.
    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        app.launchArguments = launchArguments

        app.launchArguments.append("-disableAnimations")
        app.launchArguments.append("-skipTour")
        app.launchArguments.append("-toolbarSpotlightOff")
        app.launchArguments.append("-uiTests")
        app.launchArguments.append(contentsOf: ["-com.apple.CoreData.ConcurrencyDebug", "1"])
        app.launchArguments.append(contentsOf: ["-AppleLanguages", "(en)"])

        app.launchEnvironment[apiDomainKey] = dynamicDomain

        if humanVerificationStubs {
            app.launchArguments.append(contentsOf: ["HumanVerificationStubs", "1"])
        } else if forceUpgradeStubs {
            app.launchArguments.append(contentsOf: ["ForceUpgradeStubs", "1"])
        } else if extAccountNotSupportedStub {
            app.launchArguments.append(contentsOf: ["ExtAccountNotSupportedStub", "1"])
        }

        // Disable feedback pop up
        app.launchArguments.append("-disableInAppFeedbackPromptAutoShow")

        app.launch()

        env = Environment.custom(dynamicDomain)
        quarkCommands = QuarkCommands(doh: env.doh)
        quarkCommandTwo = Quark()
            .baseUrl("https://\(dynamicDomain)/api/internal/quark")

        handleInterruption()
        disableJail()
    }

    override func tearDown() {
        terminateApp()
        super.tearDown()
    }

    func handleInterruption() {
        let labels = [LocalString._skip_btn_title, "Allow Access to All Photos", "Select Photos...", "Don’t Allow", "Keep Current Selection",LocalString._send_anyway, LocalString._general_ok_action, LocalString._hide]
        /// Adds UI interruption monitor that queries all buttons and clicks if identifier is in the labels array. It is triggered when system alert interrupts the test execution.
        addUIMonitor(elementQueryToTap: XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons, identifiers: labels)
    }
    
    fileprivate func login(user: User) {
        loginRobot.loginUser(user)
    }

    private func loadUser(userKey: String) -> String {
        if let user = ProcessInfo.processInfo.environment[userKey] {
            return user
        } else {
            return getValueForKey(key: userKey, filename: credentialsFileName)!
        }
    }

    private func getValueForKey(key: String, filename: String) -> String? {
        var data = Data()
        var params = Dictionary<String, String>()

        /// Load files from "pm.ProtonMailUITests" bundle.
        guard let fileURL = Bundle(identifier: "pm.ProtonMailUITests")!.url(forResource: filename, withExtension: "plist") else {
            fatalError("Users credentials.plist file not found.")
        }
        do {
            data = try Data(contentsOf: fileURL)
            params = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! Dictionary<String, String>
        } catch {
            fatalError("Unable to parse credentials.plist file while running UI tests.")
        }
        return params[key]
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
                try quarkCommandTwo.jailUnban()
            }
            catch {
                XCTFail(error.localizedDescription)
            }
            wasJailDisabled = true
        }
    }
    
    private static func disableAutoFillPasswords() {
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        settingsApp.launch()
        settingsApp.tables.staticTexts["PASSWORDS"].tap()

        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("1\r")

        let button = settingsApp.tables.cells["PasswordOptionsCell"].buttons["chevron"]
        _ = button.waitForExistence(timeout: 1)
        button.tap()

        let autoFillPasswordSwitch = settingsApp.switches["AutoFill Passwords"]
        if autoFillPasswordSwitch.isSwitchOn {
            autoFillPasswordSwitch.tap()
        }

        settingsApp.terminate()
    }
}

class FixtureAuthenticatedTestCase: BaseTestCase {

    var scenario: MailScenario = .qaMail001
    var plan: UserPlan { .mailpro2022 }
    var isSubscriptionIncluded: Bool { true }
    var user: User = User()

    override func setUp() {
        super.setUp()
    }
    
    func runTestWithScenario(_ actualScenario: MailScenario, testBlock: () -> Void) {
        scenario = actualScenario
        createUserAndLogin()
        testBlock()
    }

    func createUser(scenarioName: String, plan: UserPlan, isEnableEarlyAccess: Bool) -> User {
        var user: User = User()

        do {
            if scenario.name.starts(with: "qa-mail-web")  {
                let response = try quarkCommandTwo.createUserWithFixturesLoad(name: scenarioName)

                if let name = response?.name, let password = response?.password, let decryptedUserId = response?.decryptedUserId {
                    user.name = name
                    user.password = password
                    user.id = Int(decryptedUserId)
                } else {
                    XCTFail("Wrong response \(String(describing: response))")
                }

                try quarkCommandTwo.enableSubscription(id: user.id!, plan: plan.rawValue)
                try quarkCommandTwo.enableEarlyAccess(username: user.name)

            } else {
                quarkCommandTwo = Quark()
                    .baseUrl("https://\(dynamicDomain)/internal-api/quark")

                let fixtureUsers = try quarkCommandTwo.createUserWithiOSFixturesLoad(name: scenarioName)

                if let users = fixtureUsers?.users {
                    for fixtureUser in users {

                        // TODO: update for user list
                        user.name = fixtureUser.name
                        user.password = fixtureUser.password
                        user.id = fixtureUser.id.raw

                        try quarkCommandTwo.enableSubscription(id: Int(fixtureUser.id.raw), plan: plan.rawValue)
                        try quarkCommandTwo.enableEarlyAccess(username: fixtureUser.name)
                    }
                }
            }
        }
        catch {
            XCTFail(error.localizedDescription)
        }

        return user
    }

    private func createUserAndLogin() {
        user = createUser(scenarioName: scenario.name, plan: plan, isEnableEarlyAccess: true)
        login(user: user)
    }

    override func tearDown() {
        defer { super.tearDown() }
        guard let id = user.id else { return }
        do {
            try quarkCommandTwo.deleteUser(id: id)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
}

private extension XCUIElement {

    var isSwitchOn: Bool {
        let switchValue = value as? String
        return switchValue == "1"
    }

}
