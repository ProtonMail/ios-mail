// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
import ProtonCore_Doh
import ProtonCore_Environment
import ProtonCore_TestingToolkit
import ProtonCore_QuarkCommands

final class DeleteAccountTests: CleanAuthenticatedTestCase {


    private let accountDeletionRobot = AccountDeletionButtonRobot()

    @discardableResult
    private func openAccountSettings(user: User) -> AccountSettingsRobot {

        InboxRobot()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .verify.deleteAccountShown()
    }

    func testDeleteAccountExists()  {

        openAccountSettings(user: user)

        accountDeletionRobot
            .verify.accountDeletionButtonIsDisplayed(type: .staticText)
    }
    
    func testDeleteAccountCanBeClosed() {

        openAccountSettings(user: user)

        accountDeletionRobot
            .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
            .verify.accountDeletionWebViewIsOpened()
            .verify.accountDeletionWebViewIsLoaded(application: app)
            .tapCancelButton(to: AccountDeletionButtonRobot.self)
            .verify.accountDeletionButtonIsDisplayed(type: .staticText)

    }
    
    func testLoginScreenIsShownAfterSuccessfulDeletion() {

        openAccountSettings(user: user)

        accountDeletionRobot
            .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
            .verify.accountDeletionWebViewIsOpened()
            .verify.accountDeletionWebViewIsLoaded(application: app)
            .setDeletionReason()
            .fillInDeletionExplaination()
            .fillInDeletionEmail()
            .fillInDeletionPassword(user.password)
            .confirmBeingAwareAccountDeletionIsPermanent()
            .tapDeleteAccountButton(to: LoginRobot.self)
            .verify.loginScreenIsShown()
    }


    func testSecondUserInboxIsShownAfterSuccessfulDeletionOfFirstUser() {

        var user2: User = User(name: StringUtils().randomAlphanumericString(length: 8), password: StringUtils().randomAlphanumericString(length: 8), mailboxPassword: "", twoFASecurityKey: "")
        quarkCommands.createUser(username: user2.email, password: user2.password, protonPlanName: UserPlan.free.rawValue)

        openAccountSettings(user: user)
            .navigateBackToSettings()
            .close()
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectOnePassAccount(user2)
            .menuDrawer()
            .settings()
            .selectAccount(user2.email)
            .verify.deleteAccountShown()

        accountDeletionRobot
            .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
            .verify.accountDeletionWebViewIsOpened()
            .verify.accountDeletionWebViewIsLoaded(application: app)
            .setDeletionReason()
            .fillInDeletionExplaination()
            .fillInDeletionEmail()
            .fillInDeletionPassword(user2.password)
            .confirmBeingAwareAccountDeletionIsPermanent()
            .tapDeleteAccountButton(to: InboxRobot.self)
            .verify.inboxShown()
            .menuDrawer()
            .verify.currentAccount(user)
    }
}
