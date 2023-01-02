//
//  PaymentsUIRobot.swift
//  ProtonCore-TestingToolkit - Created on 25.06.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import ProtonCore_CoreTranslation
import pmtest

private let title = CoreString._pu_select_plan_title
private func planCellIdentifier(name: String) -> String {
    "PlanCell.\(name)"
}

private func currentPlanCellIdentifier(name: String) -> String {
    "CurrentPlanCell.\(name)"
}

private func selectPlanButtonIdentifier(name: String) -> String {
    "\(name).selectPlanButton"
}

private func expandPlanButtonIdentifier(name: String) -> String {
    "\(name).expandButton"
}

private let extendSubscriptionText = "PaymentsUIViewController.extendSubscriptionButton"

// System dialog definitions

private let subscribeButtonName = "Subscribe"
private let confirmButtonName = "Confirm"
private let passordTextFieldName = "Password"
private let signInButtonName = "Sign In"
private let buyButtonName = "Buy"
private let okButtonName = "OK"

public enum PaymentsPlan: String {
    case free = "Free"
    case mailPlus = "Plus"
    case pro = "Professional"
    case visionary = "Visionary"
    case mailFree = "ProtonMail_Free"
    case mail2022 = "Mail_Plus"
    case unlimited = "Proton_Unlimited"
    case none = ""
    
    var getDescription: [String] {
        switch self {
        case .free:
            return [
                "Current plan",
                "500 MB storage",
                "1 email address",
                "3 folders / labels"]
        case .mailPlus:
            return [
                "7 GB storage",
                "5 email addresses",
                "200 folders / labels",
                "Custom email addresses",
                "Priority customer support"]
        case .pro:
            return [
                "Current plan",
                "7 GB storage / user",
                "10 email addresses / user",
                "2 custom domains",
                "Multi-user support"]
        case .visionary:
            return [
                "Current plan",
                "20 GB storage",
                "50 email addresses",
                "20 calendars",
                "10 high-speed VPN connections",
                "10 custom domains",
                "6 users"]
        case .mailFree:
            return [
                "0.5 GB storage",
                "1 address",
                "1 VPN connection"]
        case .mail2022:
            return [
                "1 user",
                "1 of 10 email addresses",
                "0 of 20 personal calendars",
                "1 VPN connection"]
        case .unlimited:
            return [
                "500 GB storage",
                "15 email addresses",
                "Support for 3 custom"]
        case .none:
            return [
            "Contact an administrator to make changes to your Proton subscription."]
        }
    }
    
    var getDescriptionV5: [String] {
        switch self {
        case .free:
            return [
                "1 user",
                "1 email address",
                "1 personal calendar",
                "1 VPN connection"]
        case .mailPlus:
            return [
                "7 GB storage",
                "5 email addresses",
                "200 folders / labels",
                "Custom email addresses",
                "Priority customer support"]
        case .pro:
            return [
                "Current plan",
                "7 GB storage / user",
                "10 email addresses / user",
                "2 custom domains",
                "Multi-user support"]
        case .visionary:
            return [
                "Current plan",
                "20 GB storage",
                "50 email addresses",
                "20 calendars",
                "10 high-speed VPN connections",
                "10 custom domains",
                "6 users"]
        case .mailFree:
            return [
                "0.5 GB storage",
                "1 address",
                "1 VPN connection"]
        case .mail2022:
            return [
                "1 user",
                "1 of 10 email addresses",
                "0 of 20 personal calendars",
                "1 VPN connection"]
        case .unlimited:
            return [
                "500 GB storage",
                "15 email addresses",
                "Support for 3 custom"]
        case .none:
            return [
            "Contact an administrator to make changes to your Proton subscription."]
        }
    }
}

public final class PaymentsUIRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func paymentsUIScreenIsShown() -> PaymentsUIRobot {
            staticText(title).wait().checkExists()
            return PaymentsUIRobot()
        }
    }
    
    public func selectPlanCell(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(planCellIdentifier(name: plan.rawValue)).wait().tap()
        return self
    }
    
    public func selectCurrentPlanCell(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(currentPlanCellIdentifier(name: plan.rawValue)).wait().tap()
        return self
    }
    
    public func freePlanV3ButtonTap(wait: TimeInterval = 10.0) -> SignupHumanVerificationV3Robot.HV3OrCompletionRobot {
        button(selectPlanButtonIdentifier(name: PaymentsPlan.free.rawValue)).tap()
        return SignupHumanVerificationV3Robot().verify.isHumanVerificationRequired(wait: wait)
    }
    
    public func freePlanButtonTap() -> SignupHumanVerificationRobot.HVOrSummaryRobot {
        button(selectPlanButtonIdentifier(name: PaymentsPlan.free.rawValue)).tap()
        return SignupHumanVerificationRobot().verify.isHumanVerificationRequired()
    }
    
    public func mailFreePlanButtonTap() -> SignupHumanVerificationRobot.HVOrSummaryRobot {
        button(selectPlanButtonIdentifier(name: PaymentsPlan.mailFree.rawValue)).tap()
        return SignupHumanVerificationRobot().verify.isHumanVerificationRequired()
    }
    
    public func planButtonDoesNotExist(plan: PaymentsPlan) -> PaymentsUIRobot {
        button(selectPlanButtonIdentifier(name: plan.rawValue)).checkDoesNotExist()
        return self
    }
    
    public func planButtonSelected(plan: PaymentsPlan) -> PaymentsUIRobot {
        button(selectPlanButtonIdentifier(name: plan.rawValue)).checkExists().checkSelected()
        return self
    }
    
    @discardableResult
    public func verifyNumberOfCells(number: Int) -> PaymentsUIRobot {
        let count = XCUIApplication().tables.count
        XCTAssertEqual(count, number)
        return self
    }
    
    @discardableResult
    func verifyStaticText(_ name: String) -> Self {
        staticText(name).wait().checkExists()
        return self
    }
    
    @discardableResult
    public func verifyNumberOfPlansToPurchase(number: Int) -> PaymentsUIRobot {
        table("PaymentsUIViewController.tableView").wait().checkExists()
        let count = XCUIApplication().tables.matching(identifier: "PaymentsUIViewController.tableView").cells.count
        XCTAssertEqual(count, number)
        return self
    }
    
    @discardableResult
    public func verifyTableCellStaticText(cellName: String, name: String) -> PaymentsUIRobot {
        table("PaymentsUIViewController.tableView").wait().checkExists()
        let staticTexts = XCUIApplication().tables.matching(identifier: "PaymentsUIViewController.tableView").cells.matching(identifier: cellName).staticTexts
        XCTAssertTrue(staticTexts[name].exists)
        return self
    }
    
    @discardableResult
    public func verifyPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
        plan.getDescription.forEach {
            staticText($0).wait().checkExists()
        }
        return self
    }

    @discardableResult
    public func verifyPlanV5(plan: PaymentsPlan) -> PaymentsUIRobot {
        plan.getDescriptionV5.forEach {
            staticText($0).wait().checkExists()
        }
        return self
    }
    
    public func expandPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
         button(expandPlanButtonIdentifier(name: plan.rawValue)).tap().wait()
            return self
     }
    
    @discardableResult
    public func verifyExpirationTime() -> PaymentsUIRobot {
        let expirationString = String(format: CoreString._pu_plan_details_renew_expired, getEndDateString)
        staticText(expirationString).checkExists()
        return self
    }
    
    @discardableResult
    public func verifyRenewTime() -> PaymentsUIRobot {
        let expirationString = String(format: CoreString._pu_plan_details_renew_auto_expired, getEndDateString)
        staticText(expirationString).checkExists()
        return self
    }
    
    public func wait(timeInterval: TimeInterval) -> PaymentsUIRobot {
        Wait().wait(timeInterval: timeInterval)
        return self
    }
    
    public func planButtonTap(plan: PaymentsPlan) -> PaymentsUISystemRobot {
        button(selectPlanButtonIdentifier(name: plan.rawValue)).tap()
        return PaymentsUISystemRobot()
    }
    
    public func extendSubscriptionTap() -> PaymentsUISystemRobot {
        button(extendSubscriptionText).wait().tap()
        return PaymentsUISystemRobot()
    }
    
    public func extendSubscriptionSelected() -> PaymentsUIRobot {
        button(extendSubscriptionText).checkExists().checkSelected()
        return PaymentsUIRobot()
    }

    public final class PaymentsUISystemRobot: CoreElements {

        public func verifyPaymentIfNeeded(password: String?) -> SignupHumanVerificationRobot.HVOrSummaryRobot {
            guard isButtonExist(name: selectPlanButtonIdentifier(name: PaymentsPlan.free.rawValue)) else {
                return SignupHumanVerificationRobot().verify.isHumanVerificationRequired()
            }
            // Continue verification only if plan is not purchased yet
            
            confirmation(password: password)
            return SignupHumanVerificationRobot().verify.isHumanVerificationRequired()
        }
        
        public func verifyPayment<T: CoreElements>(robot _: T.Type, password: String?) -> T {
            Wait().wait(timeInterval: 3)
            confirmation(password: password)
            return T()
        }

        private func confirmation(password: String?) {
            #if targetEnvironment(simulator)
                systemButtonTap(name: subscribeButtonName)
                systemButtonTap(name: buyButtonName)
            #else
                systemButtonTap(name: subscribeButtonName)
                systemEditField(name: passordTextFieldName, text: password ?? "")
                systemButtonTap(name: signInButtonName)
                systemButtonTap(name: buyButtonName)
            #endif
            systemButtonTap(name: okButtonName)
        }
        
        private func isButtonExist(name: String) -> Bool {
            let button = XCUIApplication().buttons[name]
            Wait(time: 2).forElement(button)
            return button.exists
        }
        
        private func systemButtonTap(name: String) {
            let button = springboard.buttons[name]
            Wait(time: 4).forElement(button)
            button.tap()
        }
        
        private func systemEditField(name: String, text: String) {
            let textField = springboard.secureTextFields[name]
            Wait().forElement(textField)
            textField.typeText(text)
        }
        
        private var springboard: XCUIApplication {
            return XCUIApplication(bundleIdentifier: "com.apple.springboard")
        }
    }
    
    public func activateApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        app.activate()
        return T()
    }
    
    public func terminateApp<T: CoreElements>(app: XCUIApplication, robot _: T.Type) -> T {
        app.terminate()
        return T()
    }
}

extension PaymentsUIRobot {
    var getEndDateString: String {
        let today = Date()
        let date = Calendar.current.date(byAdding: .year, value: 1, to: today)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        let endDateString = dateFormatter.string(from: date)
        return endDateString
    }
}

extension Wait {
    func wait(timeInterval: TimeInterval) {
        let testCase = XCTestCase()
        let waitExpectation = testCase.expectation(description: "Waiting")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            waitExpectation.fulfill()
        }
        testCase.waitForExpectations(timeout: timeInterval + 0.5)
    }
}
