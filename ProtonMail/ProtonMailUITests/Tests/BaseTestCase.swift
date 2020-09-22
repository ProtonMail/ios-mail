//
//  BaseTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import XCTest

/**
 Parent class for all the test classes.
*/
class BaseTestCase: XCTestCase {
    
    let app = XCUIApplication()
    var launchArguments = ["-clear_all_preference", "YES"]
    let testData = TestData()
    
    override func setUp() {
        super.setUp()
        app.terminate()
        continueAfterFailure = false
        app.launchArguments = launchArguments
        app.launch()
        _ = handleInterruption()
        
        testData.onePassUser = User(user: String(Environment.variable(named: "TEST_USER1")!))
        testData.twoPassUser = User(user: String(Environment.variable(named: "TEST_USER2")!))
        testData.onePassUserWith2Fa = User(user: String(Environment.variable(named: "TEST_USER3")!))
        testData.twoPassUserWith2Fa = User(user: String(Environment.variable(named: "TEST_USER4")!))
        
        testData.internalEmailTrustedKeys = User(user: String(Environment.variable(named: "TEST_RECIPIENT1")!))
        testData.internalEmailNotTrustedKeys = User(user: String(Environment.variable(named: "TEST_RECIPIENT2")!))
        testData.externalEmailPGPEncrypted = User(user: String(Environment.variable(named: "TEST_RECIPIENT3")!))
        testData.externalEmailPGPSigned = User(user: String(Environment.variable(named: "TEST_RECIPIENT4")!))
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    func handleInterruption() -> Bool {
        addUIInterruptionMonitor(withDescription: "Allow Notifications") { (alert) -> Bool in
            let allowButton = alert.buttons["Don’t Allow"]
            if allowButton.exists {
                allowButton.tap()
            }
            return true
        }
        return false
    }
    
    struct Environment {
        static func variable(named name: String) -> String? {
            let processInfo = ProcessInfo.processInfo
            guard let value = processInfo.environment[name] else {
                return nil
            }
            return value
        }
    }
}
