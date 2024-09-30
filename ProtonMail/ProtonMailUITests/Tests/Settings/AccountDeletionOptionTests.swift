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

import ProtonCoreTestingToolkitUITestsAccountDeletion
import ProtonCoreTestingToolkitUITestsLogin

// Validates account deletion option in the app without actual deletion.
class AccountDeletionOptionTests: FixtureAuthenticatedTestCase {
    
    let accountDeletionRobot = AccountDeletionButtonRobot()
    
    func testDeleteAccountOptionExists() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.email)
            
            accountDeletionRobot
                .verify.accountDeletionButtonIsDisplayed(type: .staticText)
        }
    }
    
    func testDeleteAccountCanBeClosed() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.email)
            
            accountDeletionRobot
                .openAccountDeletionWebView(type: .staticText, to: AccountDeletionWebViewRobot.self)
                .verify.accountDeletionWebViewIsOpened()
                .verify.accountDeletionWebViewIsLoaded(application: app)
                .tapCancelButton(to: AccountDeletionButtonRobot.self)
                .verify.accountDeletionButtonIsDisplayed(type: .staticText)
        }
    }
}
