// Copyright (c) 2023. Proton Technologies AG
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

import XCTest

import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsPaymentsUI
import StoreKitTest

class SubscriptionTests: FixtureAuthenticatedTestCase {

    override var plan : UserPlan { .free }
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Proton Mail - Encrypted Email")
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testUpgradeAccountFromFreeToUnlimited() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .subscription()
                .expandPlan(plan: .unlimited)
                .planButtonTap(plan: .unlimited)
                
            PaymentsUIRobot()
                .verifyCurrentPlan(plan: .unlimited)
                .verifyExtendButton()
        }
    }


    func testUpgradeAccountFromFreeToMail2022() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .subscription()
                .expandPlan(plan: .mail2022)
                .planButtonTap(plan: .mail2022)

            PaymentsUIRobot()
                .verifyCurrentPlan(plan: .mail2022)
                .verifyExtendButton()
        }
    }
}


extension PaymentsUIRobot {

    private func currentPlanCellIdentifier(name: String) -> String {
        "CurrentPlanCell.\(name)"
    }

    func verifyCurrentPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(currentPlanCellIdentifier(name: plan.rawValue)).waitUntilExists(time: 20).checkExists()
        return self
    }

    @discardableResult
    func verifyExtendButton() -> PaymentsUIRobot {
        let extendSubscriptionText = "PaymentsUIViewController.extendSubscriptionButton"
        button(extendSubscriptionText).waitUntilExists().checkExists()
        return self
    }
}
