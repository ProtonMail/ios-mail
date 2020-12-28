//
//  ReportTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/11.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

class ReportTests: BaseTestCase {
    
    func testEditAndSendBugReport() {
        let user = testData.onePassUser
        let topic = "This is an automation test bug report"
        
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .reports()
            .sendBugReport(topic)
    }
}
