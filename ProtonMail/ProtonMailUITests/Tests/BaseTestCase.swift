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

let apiDomainKey = "MAIL_APP_API_DOMAIN"
var environmentFileName = "environment"
var credentialsFileName = "credentials"
let credentialsBlackFileName = "credentials_black"
let testData = TestData()

var dynamicDomain: String? {
    let domain = ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"]
    return domain?.isEmpty == false ? domain : ""
}

/**
 Parent class for all the test classes.
 */
class BaseTestCase: CoreTestCase, QuarkTestable {

    var launchArguments = ["-clear_all_preference", "YES"]
    var humanVerificationStubs = false
    var forceUpgradeStubs = false
    var extAccountNotSupportedStub = false
    var usesBlackCredentialsFile = true
    private let loginRobot = LoginRobot()

    var env: Environment = .black
    lazy var quarkCommands = QuarkCommands(doh: env.doh)

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false

        setupTest()
    }

    @MainActor
    func login(user: User) {
        loginRobot
            .loginUser(user)
    }

    @MainActor
    func terminateApp() {
        app.terminate()
    }

    @MainActor
    func setupTest() {

        continueAfterFailure = false

        app.launchArguments = launchArguments

        app.launchArguments.append("-disableAnimations")
        app.launchArguments.append("-skipTour")
        app.launchArguments.append("-toolbarSpotlightOff")
        app.launchArguments.append("-uiTests")

        app.launchEnvironment[apiDomainKey] = dynamicDomain!

        if humanVerificationStubs {
            app.launchEnvironment["HumanVerificationStubs"] = "1"
        } else if forceUpgradeStubs {
            app.launchEnvironment["ForceUpgradeStubs"] = "1"
        } else if extAccountNotSupportedStub {
            app.launchEnvironment["ExtAccountNotSupportedStub"] = "1"
        }
        app.launch()

        env = Environment.custom(dynamicDomain!)
        quarkCommands = QuarkCommands(doh: env.doh)

        handleInterruption()
    }

    override func tearDown() async throws {
        await terminateApp()
        try await super.tearDown()
    }

    func handleInterruption() {
        let labels = [LocalString._skip_btn_title, "Allow Access to All Photos", "Select Photos...", "Don’t Allow", "Keep Current Selection",LocalString._send_anyway, LocalString._general_ok_action, LocalString._hide]
        /// Adds UI interruption monitor that queries all buttons and clicks if identifier is in the labels array. It is triggered when system alert interrupts the test execution.
        addUIMonitor(elementQueryToTap: XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons, identifiers: labels)
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
}

@available(iOS 16.0, *)
class CleanAuthenticatedTestCase: BaseTestCase {

    var user: User = User(name: StringUtils().randomAlphanumericString(length: 8), password: StringUtils().randomAlphanumericString(length: 8), mailboxPassword: "", twoFASecurityKey: "")

    override func setUp() async throws {
        try await super.setUp()

        quarkCommands.createUser(username: user.name, password: user.password, protonPlanName: UserPlan.mailpro2022.rawValue)

        login(user: user)
    }

    override func tearDown() async throws {
        try await deleteUser(domain: dynamicDomain!, user)
        try await super.tearDown()
    }
}

@available(iOS 16.0, *)
class FixtureAuthenticatedTestCase: BaseTestCase {

    var user: User?
    var scenario: MailScenario { .qaMail001 }
    var isSubscriptionIncluded: Bool { true }

    override func setUp() async throws {
        let user = try await createUserWithFixturesLoad(domain: dynamicDomain!, plan: UserPlan.mailpro2022, scenario: scenario, isEnableEarlyAccess: false)
        self.user = user

        try await super.setUp()

        login(user: user)
    }

    override func tearDown() async throws {
        try await deleteUser(domain: dynamicDomain!, user)
        try await super.tearDown()
    }

    open override func record(_ issue: XCTIssue) {
        var myIssue = issue
        var issueDescription: String = "\n"
        issueDescription.append("User:")
        issueDescription.append("\n")
        issueDescription.append(user.debugDescription)
        issueDescription.append("\n\n")
        issueDescription.append("Failure:")
        issueDescription.append("\n\(myIssue.compactDescription)")

        myIssue.compactDescription = issueDescription
        super.record(myIssue)
    }
}

