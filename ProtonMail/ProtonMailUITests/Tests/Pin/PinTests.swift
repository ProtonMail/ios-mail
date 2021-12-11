//
//  PinTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/17.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import ProtonCore_TestingToolkit

class PinTests: BaseTestCase {

    private let correctPin = "0000"
    private let pinRobot: PinRobot = PinRobot()
    private let loginRobot = LoginRobot()

    override func setUp() {
        super.setUp()
        loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .settings()
            .pin()
            .enablePin()
            .setPin(correctPin)
            .verify.isPinEnabled(true)
    }
    
    func testTurnOnAndOffPin() {
        pinRobot
            .disablePin()
            .verify.isPinEnabled(false)
    }
    
    func testEnterCorrectPinCanUnlock() {
        pinRobot
            .backgroundApp()
            .foregroundApp()
            .confirmWithEmptyPin()
            .verify.emptyPinErrorMessageShows()
            .clickOK()
            .inputCorrectPin()
            .verify.appUnlockSuccessfully()
    }
    
    func testEnterIncorrectPinCantUnlock() {
        pinRobot
            .backgroundApp()
            .foregroundApp()
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(1)
            .inputIncorrectPin()
            .verify.pinErrorMessageShows(2)
            .logout()
            .verify.loginScreenIsShown()
    }
}
