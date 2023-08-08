//
//  SettingsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 31.12.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class SettingsTests : FixtureAuthenticatedTestCase {
    
    private let correctPin = "0000"
    private let inboxRobot: InboxRobot = InboxRobot()

    func testEditAutoLockTime() {
        inboxRobot
            .menuDrawer()
            .settings()
            .pin()
            .enablePin()
            .setPin(correctPin)
            .openPinTimerSelection()
            .selectAutoLockNone()
            .navigateUpToSettings()
            .close()
            .backgroundAppWithoutPin()
            .activateAppWithoutPin()
            .menuDrawer()
            .settings()
            .pin()
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .verify.inboxShown()
    }

    @MainActor
    func testEnableAndDisablePinForMultipleAccounts() throws {
        let secondAccount = try createUserWithFixturesLoad(domain: dynamicDomain, plan: UserPlan.mailpro2022, scenario: scenario, isEnableEarlyAccess: false)

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
            .openPinTimerSelection()
            .selectAutolockEveryTime()
            .navigateUpToSettings()
            .close()
            .backgroundApp()
            .activateAppWithPin()
            .inputCorrectPin()
            .verify.inboxShown()
            .menuDrawer()
            .accountsList()
            .switchToAccount(user!)
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

    func testBlockList() {
        inboxRobot
            .menuDrawer()
            .settings()
            .selectAccount(user!.email)
            .blockList()
            .pullDownToRefresh()
            .verify
            .expectedTitleIsShown()
            .emptyListPlaceholderIsShown()
    }
}
