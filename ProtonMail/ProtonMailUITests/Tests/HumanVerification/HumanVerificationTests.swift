//
//  HumanVerificationTests.swift
//  ProtonMailUITests
//
//  Created by Greg on 16.04.21.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import XCTest
import ProtonCore_TestingToolkit

class HumanVerificationTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var menuRobot = MenuRobot()
    private var humanVerificationRobot = HumanVerificationRobot()

    override func setUp() {
        humanVerificationStubs = true
        super.setUp()

        menuRobot = loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
    }

    func testHumanVerification() {
        menuRobot
            .subscriptionAsHumanVerification()
            .verify.humanVerificationScreenIsShown()
            .emailTab()
            .smsTab()
            .captchaTab()
            .close(to: MenuRobot.self)
            .paymentsErrorDialog()      
    }
}
