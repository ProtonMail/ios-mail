//
//  BaseTest.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import XCTest
import pmtest

let appDomainKey = "MAIL_APP_API_DOMAIN"
let appPathKey = "MAIL_APP_API_PATH"
let environmentFileName = "environment"
var credentialsFileName = "credentials"
let credentialsBlackFileName = "credentials_black"
let testData = TestData()
var domain: String?
var path: String?

/**
 Parent class for all the test classes.
*/
class BaseTestCase: XCTestCase {
    
    var launchArguments = ["-clear_all_preference", "YES"]
    var humanVerificationStubs = false
    var forceUpgradeStubs = false

    override class func setUp() {
        super.setUp()
        
        /// Get api domain and path from environment variables.
        domain = ProcessInfo.processInfo.environment[appDomainKey]
        path = ProcessInfo.processInfo.environment[appPathKey]

        /// Fall back to local values stored in environment.plist file id domain or path is nil. Update it to run tests locally against dev environment.
        if domain == nil || path == nil {
            domain = getValueForKey(key: appDomainKey, filename: environmentFileName)!
            path = getValueForKey(key: appPathKey, filename: environmentFileName)!
        }
        
        if domain!.contains("black") {
            /// Use "credentials_black.plist" in this case.
            credentialsFileName = credentialsBlackFileName
            app.launchArguments.append("-uiTests")
            app.launchEnvironment[appDomainKey] = domain!
            app.launchEnvironment[appPathKey] = path!
        }
        
        testData.onePassUser = User(user: loadUser(userKey: "TEST_USER1"))
        testData.twoPassUser = User(user: loadUser(userKey: "TEST_USER2"))
        testData.onePassUserWith2Fa = User(user: loadUser(userKey: "TEST_USER3"))
        testData.twoPassUserWith2Fa = User(user: loadUser(userKey: "TEST_USER4"))
        
        testData.internalEmailTrustedKeys = User(user: loadUser(userKey: "TEST_RECIPIENT1"))
        testData.internalEmailNotTrustedKeys = User(user: loadUser(userKey: "TEST_RECIPIENT2"))
        testData.externalEmailPGPEncrypted = User(user: loadUser(userKey: "TEST_RECIPIENT3"))
        testData.externalEmailPGPSigned = User(user: loadUser(userKey: "TEST_RECIPIENT4"))
    }
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        app.terminate()
        app.launchArguments = launchArguments
        app.launchArguments.append("-disableAnimations")
        app.launchArguments.append("-skipTour")
        
        if humanVerificationStubs {
            app.launchEnvironment["HumanVerificationStubs"] = "1"
        } else if forceUpgradeStubs {
            app.launchEnvironment["ForceUpgradeStubs"] = "1"
        }

        app.launch()
        
        handleInterruption()
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    func handleInterruption() {
        let labels = [LocalString._skip_btn_title, "Allow Access to All Photos", "Select Photos...", "Don’t Allow", "Keep Current Selection",LocalString._send_anyway, LocalString._general_ok_action, LocalString._hide]
        /// Adds UI interruption monitor that queries all buttons and clicks if identifier is in the labels array. It is triggered when system alert interrupts the test execution.
        addUIMonitor(elementQueryToTap: XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons, identifiers: labels)
    }
    
    private static func loadUser(userKey: String) -> String {
        guard let user = getValueForKey(key: userKey, filename: credentialsFileName) else {
            return "stub,stub,stub,stub"
        }
        return user
    }
    
    private static func getValueForKey(key: String, filename: String) -> String? {
        var data = Data()
        var params = Dictionary<String, String>()
        
        /// Load files from "pm.ProtonMailUITests" bunble.
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
