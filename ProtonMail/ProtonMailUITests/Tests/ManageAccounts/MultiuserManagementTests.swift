//
//  MultiuserManagementTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsLogin

class MultiuserManagementTests : FixtureAuthenticatedTestCase {

    private let loginRobot = LoginRobot()

    func testAddSecondAccount_FreeUser() throws {

        runTestWithScenario(.qaMail001) {
            let secondAccount = createUser(scenarioName: MailScenario.qaMail001.name, plan: UserPlan.free, isEnableEarlyAccess: false)

            InboxRobot()
                .menuDrawer()
                .accountsList()
                .manageAccounts()
                .addAccount()
                .connectOnePassAccount(secondAccount)
                .menuDrawer()
                .accountsList()
                .verify.accountNameEmail(user)
                .verify.accountNameEmail(secondAccount)
        }
    }

    func testAddSecondAccount_Mail2022User() throws {
        runTestWithScenario(.qaMail001) {
            let secondAccount = createUser(scenarioName: MailScenario.qaMail001.name, plan: UserPlan.mail2022, isEnableEarlyAccess: false)

            InboxRobot()
                .menuDrawer()
                .accountsList()
                .manageAccounts()
                .addAccount()
                .connectOnePassAccount(secondAccount)
                .menuDrawer()
                .accountsList()
                .verify.accountNameEmail(user)
                .verify.accountNameEmail(secondAccount)
        }
    }


    // enable and refactor to use quark commands back after the smoke set is finished
    func xtestConnectTwoPassAccountWithTwoFa() {
        let onePassUser = testData.onePassUser
        let twoPassUserWith2Fa = testData.twoPassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccountWithTwoFa(twoPassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .verify.accountNameEmail(onePassUser)
            .verify.accountNameEmail(twoPassUserWith2Fa)
    }

    func xtestConnectOnePassAccountWithTwoFa() {
        let onePassUser = testData.onePassUser
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectOnePassAccountWithTwoFa(onePassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .verify.accountNameEmail(onePassUser)
            .verify.accountNameEmail(onePassUserWith2Fa)
    }

    func xtestLogoutPrimaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutPrimaryAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .verify.accountSignedOut(twoPassUser.name)
    }

    func xtestLogoutSecondaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutSecondaryAccount(onePassUser)
            .closeManageAccounts()
            .menuDrawer()
            .accountsList()
            .verify.accountSignedOut(onePassUser.name)
    }

    func xtestRemovePrimaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot.loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutPrimaryAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .deleteAccount(twoPassUser)
            .verify.accountRemoved(twoPassUser)
    }

    func xtestRemoveSecondaryAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .logoutSecondaryAccount(onePassUser)
            .closeManageAccounts()
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .deleteAccount(onePassUser)
            .verify.accountRemoved(onePassUser)
    }

    func xtestCancelLoginOnTwoFaPrompt() {
        let onePassUser = testData.onePassUser
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .cancelLoginOnTwoFaPrompt(onePassUserWith2Fa)
            .closeManageAccounts()
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .verify.accountRemoved(onePassUserWith2Fa)
    }

    func xtestAddTwoFreeAccounts() {
        let twoPassUserWith2Fa = testData.twoPassUserWith2Fa
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginTwoPasswordUserWithTwoFA(twoPassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectSecondFreeOnePassAccountWithTwoFa(onePassUserWith2Fa)
            .verify.limitReachedDialogDisplayed()
    }

    /// DIsabled due to issue with account switcher identifiers - we should use email instead of the account name.
    func xtestSwitchAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(twoPassUser)
            .menuDrawer()
            .accountsList()
            .switchToAccount(onePassUser)
            .menuDrawer()
            .verify.currentAccount(onePassUser)
    }
}
