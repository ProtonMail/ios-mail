//
//  SettingsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 31.12.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class SettingsTests : BaseTestCase {
    
    let correctPins = [0,0,0]
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
            .enableAndSetPin(correctPins)
            .autoLockTimer()
            .selectAutoLockNone()
            .backgroundApp()
            .activateAppWithoutPin()
            .autoLockTimer()
            .selectAutolockEveryTime()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin(correctPins)
            .verify.appUnlockSuccessfully()
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
            .enableAndSetPin(correctPins)
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin(correctPins)
            .navigateUpToSettings()
            .menuDrawer()
            .accountsList()
            .switchToAccount(testData.onePassUser)
            .menuDrawer().settings()
            .pin()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin(correctPins)
            .verify.appUnlockSuccessfully()
    }
}

