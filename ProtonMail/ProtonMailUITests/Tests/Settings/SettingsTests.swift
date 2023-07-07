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

    override func setUp() {
        super.setUp()

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
        }
    }

    func testEditAutoLockTime() {
        MenuRobot()
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
            .closeYourFeedbackView()
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

        MenuRobot()
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
        MenuRobot()
            .settings()
            .selectDarkMode()
            .selectAlwaysOn()
            .navigateBackToSettings()
            .verify.darkModeIsOn()
    }
    
    func testDarkModeDisabled() {
        MenuRobot()
            .settings()
            .selectDarkMode()
            .selectAlwaysOn()
            .selectAlwaysOff()
            .navigateBackToSettings()
            .verify.darkModeIsOff()
    }

    func testBlockList() {
        MenuRobot()
            .settings()
            .selectAccount(user!.email)
            .blockList()
            .pullDownToRefresh()
            .verify
            .expectedTitleIsShown()
            .emptyListPlaceholderIsShown()
    }
}
