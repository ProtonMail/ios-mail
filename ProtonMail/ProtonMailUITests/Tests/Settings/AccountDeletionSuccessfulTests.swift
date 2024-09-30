// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreTestingToolkitUITestsAccountDeletion
import ProtonCoreTestingToolkitUITestsLogin

// Validates account deletion in the app without successful deletion.
class AccountDeletionSuccessfulTests: FixtureAuthenticatedTestCase {
    
    let accountDeletionRobot = AccountDeletionButtonRobot()
    
    func testLoginScreenIsShownAfterSuccessfulDeletion() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.email)

            accountDeletionRobot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .setDeletionReason()
                .fillInDeletionExplaination()
                .fillInDeletionEmail()
                .confirmBeingAwareAccountDeletionIsPermanent()
                .tapDeleteAccountButton(to: AccountDeletionWebViewRobot.self)
                .fillInDeletionPassword(user.password)
                .tapAuthenticateButton(to: LoginRobot.self)
                .verify.loginScreenIsShown()
        }
    }

    func testSecondUserInboxIsShownAfterSuccessfulDeletionOfFirstUser() {
        runTestWithScenario(.qaMail001) {
            let proUser = createUser()

            InboxRobot()
                .menuDrawer()
                .accountsList()
                .manageAccounts()
                .addAccount()
                .connectOnePassAccount(proUser)
                .menuDrawer()
                .accountsList()
                .switchToAccount(user)
                .menuDrawer()
                .settings()
                .selectAccount(user.email)

            accountDeletionRobot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .setDeletionReason()
                .fillInDeletionExplaination()
                .fillInDeletionEmail()
                .confirmBeingAwareAccountDeletionIsPermanent()
                .tapDeleteAccountButton(to: AccountDeletionWebViewRobot.self)
                .fillInDeletionPassword(user.password)
                .tapAuthenticateButton(to: InboxRobot.self)
                .verify.inboxShown()
                .menuDrawer()
                .verify.currentAccount(proUser)
        }
    }
}
