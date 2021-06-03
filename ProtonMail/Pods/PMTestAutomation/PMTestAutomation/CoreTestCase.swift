//
//  File.swift
//  PMTestAutomation
//
//  Created by denys zelenchuk on 02.02.21.
//

import Foundation
import XCTest
import SwiftOTP

var issueDescription = "\n\nStart →\n"

/**
 Parent class for all test classes.
*/
open class CoreTestCase: XCTestCase {

    open override func setUp() {
        super.setUp()
        _ = handleInterruption()
    }

    open override func record(_ issue: XCTIssue) {
        var myIssue = issue
        if shouldRecordStacktrace {
            issueDescription.append("→ Failure\n")
            issueDescription.append("\n\(myIssue.compactDescription)")
            myIssue.compactDescription = issueDescription
        }
        super.record(myIssue)
    }

    open override func tearDown() {
        XCUIApplication().terminate()
        issueDescription = "\n\nStart →\n"
        super.tearDown()
    }

    internal func setShouldRecordStacktrace(to value: Bool) {
        shouldRecordStacktrace = value
    }

    func handleInterruption() -> Bool {
        addUIInterruptionMonitor(withDescription: "Handle system alerts") { (alert) -> Bool in
            let buttonLabels = ["Don’t Allow"] /// Don't allow notifications
            for (label) in buttonLabels {
                let element = alert.buttons[label].firstMatch
                if element.exists {
                    element.tap()
                    break
                }
            }
            return true
        }
        return false
    }
}
