//
//  MultiuserManagementTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class MultiuserManagementTests : BaseTestCase {

    private let loginRobot = LoginRobot()

    func testConnectOnePassAccount() {
        let onePassUser = testData.onePassUser
        let twoPassUser = testData.twoPassUser
        loginRobot
            .loginTwoPasswordUser(twoPassUser)
            .decryptMailbox(twoPassUser.mailboxPassword)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectOnePassAccount(onePassUser)
            .menuDrawer()
            .accountsList()
            .verify.accountAdded(onePassUser)
    }

    func testConnectTwoPassAccount() {
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
            .verify.accountAdded(twoPassUser)
    }

    func testConnectTwoPassAccountWithTwoFa() {
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
            .verify.accountAdded(twoPassUserWith2Fa)
    }

    func testConnectOnePassAccountWithTwoFa() {
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
            .verify.accountAdded(onePassUserWith2Fa)
    }

    func testRemoveAllAccounts() {
        let onePassUser = testData.onePassUser
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .removeAllAccounts()
            .verify.loginScreenDisplayed()
    }

    func testLogoutPrimaryAccount() {
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
            .logoutAccount(twoPassUser.email)
            .verify.accountLoggedOut(twoPassUser.email)
    }

    func testLogoutSecondaryAccount() {
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
            .logoutAccount(onePassUser.email)
            .verify.accountLoggedOut(onePassUser.email)
    }

    func testRemovePrimaryAccount() {
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
            .logoutAccount(twoPassUser.email)
            .deleteAccount(twoPassUser.email)
            .verify.accountRemoved(twoPassUser.email)
    }

    func testRemoveSecondaryAccount() {
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
            .logoutAccount(onePassUser.email)
            .deleteAccount(onePassUser.email)
            .verify.accountRemoved(onePassUser.email)
    }

    func testCancelLoginOnTwoFaPrompt() {
        let onePassUser = testData.onePassUser
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginUser(onePassUser)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .cancelLoginOnTwoFaPrompt(onePassUserWith2Fa)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .verify.accountRemoved(onePassUserWith2Fa.email)
    }

    func testAddTwoFreeAccounts() {
        let twoPassUserWith2Fa = testData.twoPassUserWith2Fa
        let onePassUserWith2Fa = testData.onePassUserWith2Fa
        loginRobot
            .loginTwoPasswordUserWithTwoFA(twoPassUserWith2Fa)
            .decryptMailbox(twoPassUserWith2Fa.mailboxPassword)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectSecondFreeOnePassAccountWithTwoFa(onePassUserWith2Fa)
            .verify.limitReachedDialogDisplayed()
    }

    func testSwitchAccount() {
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
            .accountsList()
            .manageAccounts()
            .verify.switchedToAccount(onePassUser)
    }
}
