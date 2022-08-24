//
//  SettingsTests.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 31.12.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class SettingsTests : BaseTestCase {
    
    private let correctPin = "0000"
    private let inboxRobot: InboxRobot = InboxRobot()
    private let loginRobot = LoginRobot()

    override func setUp() {
        super.setUp()
        loginRobot
            .loginUser(testData.onePassUser)
    }

    func testEditAutoLockTime() {
        inboxRobot
            .menuDrawer()
            .settings()
            .pin()
            .enablePin()
            .setPin(correctPin)
            .pinTimmer()
            .selectAutoLockNone()
            .navigateUpToSettings()
            .close()
            .backgroundAppWithoutPin()
            .activateAppWithoutPin()
            .menuDrawer()
            .settings()
            .pin()
            .pinTimmer()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .verify.inboxShown()
    }
    
    func testEnableAndDisablePinForMultipleAccounts() {
        let secondAccount = testData.twoPassUser
        inboxRobot
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(secondAccount)
            .menuDrawer()
            .settings()
            .pin()
            .enablePin()
            .setPin(correctPin)
            .pinTimmer()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .menuDrawer()
            .accountsList()
            .switchToAccount(testData.onePassUser)
            .menuDrawer()
            .settings()
            .pin()
            .disablePin()
            .navigateUpToSettings()
            .close()
            .backgroundAppWithoutPin()
            .activateAppWithoutPin()
            .verify.inboxShown()
    }
    
    func testDarkModeEnable() {
      inboxRobot
            .menuDrawer()
            .settings()
            .selectDarkMode()
            .selectAlwaysOn()
            .navigateBackToSettings()
            .verify.darkModeIsOn()
    }
    
    func testDarkModeDisabled() {
      inboxRobot
            .menuDrawer()
            .settings()
            .selectDarkMode()
            .selectAlwaysOn()
            .selectAlwaysOff()
            .navigateBackToSettings()
            .verify.darkModeIsOff()
    }
}
