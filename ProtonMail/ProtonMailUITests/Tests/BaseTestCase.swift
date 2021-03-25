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
        handleInterruption()
        
        testData.onePassUser = User(user: loadUser(userKey: "TEST_USER1"))
        testData.twoPassUser = User(user: loadUser(userKey: "TEST_USER2"))
        testData.onePassUserWith2Fa = User(user: loadUser(userKey: "TEST_USER3"))
        testData.twoPassUserWith2Fa = User(user: loadUser(userKey: "TEST_USER4"))
        
        testData.internalEmailTrustedKeys = User(user: loadUser(userKey: "TEST_RECIPIENT1"))
        testData.internalEmailNotTrustedKeys = User(user: loadUser(userKey: "TEST_RECIPIENT2"))
        testData.externalEmailPGPEncrypted = User(user: loadUser(userKey: "TEST_RECIPIENT3"))
        testData.externalEmailPGPSigned = User(user: loadUser(userKey: "TEST_RECIPIENT4"))
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    func handleInterruption() {
        var flag = false
        addUIInterruptionMonitor(withDescription: "Handle system alerts") { (alert) -> Bool in
            let buttonLabels = ["Allow Access to All Photos", "Don’t Allow", "OK"]
            for (_, label) in buttonLabels.enumerated() {
                let element = alert.buttons[label].firstMatch
                if element.exists {
                    element.tap()
                    flag = true
                    break
                }
            }
            return flag
        }
    }
    
    private func loadUser(userKey: String) -> String {
        var data = Data()
        var users = Dictionary<String, String>()
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: "credentials", withExtension:"plist") else {
            fatalError("Users credentials.plist file not found.")
        }
        do {
            data = try Data(contentsOf: fileURL)
            users = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! Dictionary<String, String>
        } catch {
            fatalError("Unable to parse credentials.plist file while running UI tests.")
        }
        return users[userKey] ?? "stub,stub,stub,stub"
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
