//
//  PaymentsUIMock.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_PaymentsUI

class PaymentsUIMock: PaymentsUIProtocol {

    @FuncStub(PaymentsUIMock.showSignupPlans) var showSignupPlans
    func showSignupPlans(
        viewController: UIViewController,
        completionHandler: @escaping ((PaymentsUIResultReason) -> Void)
    ) {
        showSignupPlans(viewController, completionHandler)
    }

    @FuncStub(PaymentsUIMock.showCurrentPlan) var showCurrentPlan
    func showCurrentPlan(
        presentationType: PaymentsUIPresentationType,
        backendFetch: Bool,
        updateCredits: Bool,
        completionHandler: @escaping ((PaymentsUIResultReason) -> Void)
    ) {
        showCurrentPlan(presentationType, backendFetch, updateCredits, completionHandler)
    }

    @FuncStub(PaymentsUIMock.showUpgradePlan) var showUpgradePlan
    func showUpgradePlan(
        presentationType: PaymentsUIPresentationType,
        backendFetch: Bool,
        updateCredits: Bool,
        completionHandler: @escaping ((PaymentsUIResultReason) -> Void)
    ) {
        showUpgradePlan(presentationType, backendFetch, updateCredits, completionHandler)
    }

}
