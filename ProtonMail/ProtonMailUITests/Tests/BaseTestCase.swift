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

var dynamicDomain: String {
    ProcessInfo.processInfo.environment["DYNAMIC_DOMAIN"] ?? ""
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

    func terminateApp() {
        app.terminate()
    }

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        app.launchArguments = launchArguments

        app.launchArguments.append("-disableAnimations")
        app.launchArguments.append("-skipTour")
        app.launchArguments.append("-toolbarSpotlightOff")
        app.launchArguments.append("-uiTests")

        app.launchEnvironment[apiDomainKey] = dynamicDomain

        if humanVerificationStubs {
            app.launchEnvironment["HumanVerificationStubs"] = "1"
        } else if forceUpgradeStubs {
            app.launchEnvironment["ForceUpgradeStubs"] = "1"
        } else if extAccountNotSupportedStub {
            app.launchEnvironment["ExtAccountNotSupportedStub"] = "1"
        }
        app.launch()

        env = Environment.custom(dynamicDomain)
        quarkCommands = QuarkCommands(doh: env.doh)

        handleInterruption()
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
}

@available(iOS 16.0, *)
class FixtureAuthenticatedTestCase: BaseTestCase {

    var scenario: MailScenario { .qaMail001 }
    var plan: UserPlan { .mailpro2022 }
    var isSubscriptionIncluded: Bool { true }
    var user: User?

    override func setUp() {
        super.setUp()

        login(user: user!)
    }

    override func setUpWithError() throws {
        user = try createUserWithFixturesLoad(domain: dynamicDomain, plan: plan, scenario: scenario, isEnableEarlyAccess: false)
    }

    override func tearDownWithError() throws {
        try deleteUser(domain: dynamicDomain, user)
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

