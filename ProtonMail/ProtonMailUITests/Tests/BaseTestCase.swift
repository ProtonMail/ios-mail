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
    
    override func setUp() {
        super.setUp()
        app.terminate()
        continueAfterFailure = false
        app.launchArguments = launchArguments
        app.launch()
        _ = handleInterruption()
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
}
