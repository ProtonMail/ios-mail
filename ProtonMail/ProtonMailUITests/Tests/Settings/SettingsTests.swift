//
//  SettingsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 31.12.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreQuarkCommands

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

    func testEnableAndDisablePinForMultipleAccounts() throws {
        let secondAccount = createUser(scenarioName: scenario.name, plan: UserPlan.mailpro2022, isEnableEarlyAccess: false)

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
            .switchToAccount(user)
            .menuDrawer()
            .settings()
            .pin()
            .disablePin()
            .enterPin(correctPin)
            .continueWithCorrectPin()
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
            .selectAccount(user.email)
            .blockList()
            .pullDownToRefresh()
            .verify.expectedTitleIsShown()
            .verify.emptyListPlaceholderIsShown()
    }
    
    func testDefaultSwipeActions() {
        MenuRobot()
            .settings()
            .openSwipeActions()
            .selectLeftToRight()
            .verify.leftToRightIsMoveToTrash()
            .backButton()
            .selectRightToLeft()
            .verify.rightToLeftIsMoveToArchive()
    }
        
    func testCustomSwipeActions() {
        MenuRobot()
            .settings()
            .openSwipeActions()
            .selectLeftToRight()
            .selectMoveToSpam()
            .verify.leftToRightIsMoveToSpam()
            .backButton()
            .selectRightToLeft()
            .selectLabelAs()
            .verify.rightToLeftIsLabelAs()
    }
}

