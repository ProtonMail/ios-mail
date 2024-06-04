//
//  ReportTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/11.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest

class ReportTests: FixtureAuthenticatedTestCase {
    
    func testEditAndSendBugReport() {
        let topic = "This is an automation test bug report"
        
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .reports()
                .sendBugReport(topic)
        }
    }
}
