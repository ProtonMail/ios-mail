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

import ProtonCoreTestingToolkitUITestsLogin

class ReferralPromptTests: FixtureAuthenticatedTestCase {

    override func setUp() {
        launchArguments.append("-showReferralPromptView")
        super.setUp()
    }

    func testTapOutsideShouldDismiss() {
        runTestWithScenarioDoNotLogin(.qaMail001) {
            LoginRobot()
                .loginUserWithReferralPrompt(user)
                .dismissReferralByTapOutside()
                .verify.referralPromptIsNotShown()
        }
    }

    func testCloseButtonShouldDismiss() {
        runTestWithScenarioDoNotLogin(.qaMail001) {
            LoginRobot()
                .loginUserWithReferralPrompt(user)
                .dismissReferralWithCloseButton()
                .verify.referralPromptIsNotShown()
        }
    }

    func testLaterButtonShouldDismiss() {
        runTestWithScenarioDoNotLogin(.qaMail001) {
            LoginRobot()
                .loginUserWithReferralPrompt(user)
                .dismissReferralWithLaterButton()
                .verify.referralPromptIsNotShown()
        }
    }
}
