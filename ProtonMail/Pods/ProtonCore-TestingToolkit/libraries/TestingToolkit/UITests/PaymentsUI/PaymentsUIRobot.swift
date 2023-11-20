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

#if canImport(fusion)

import XCTest
import ProtonCorePaymentsUI
import fusion

private let title = PUITranslations.select_plan_title.l10n
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
    case visionary = "Visionary"
    case mailFree = "ProtonMail_Free"
    case mail2022 = "Mail_Plus"
    case drive2022 = "Drive_Plus"
    case vpn2022 = "VPN_Plus"
    case pass2022 = "Pass_Plus"
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
                "0 of 20 calendars",
                "1 VPN connection"]
        case .drive2022:
            return [
                "1 user",
                "1 of 15 email addresses",
                "0 of 25 personal calendars",
                "10 VPN connection"]
        case .vpn2022:
            return [
                "10 VPN connections",
                "Highest VPN speed",
                "1500+ servers in 51 countries"]
        case .pass2022:
            return [
                "Unlimited logins and notes",
                "Unlimited devices",
                "20 vaults"]
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
                "1 calendar",
                "1 VPN connection"]
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
                "0 of 20 calendars",
                "1 VPN connection"]
        case .drive2022:
            return [
                "1 user",
                "1 of 15 email addresses",
                "0 of 25 personal calendars",
                "10 VPN connection"]
        case .vpn2022:
            return [
                "10 VPN connections",
                "Highest VPN speed",
                "1500+ servers in 51 countries"]
        case .pass2022:
            return [
                "Unlimited logins and notes",
                "Unlimited devices",
                "20 vaults"]
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
            staticText(title).waitUntilExists().checkExists()
            return PaymentsUIRobot()
        }
    }

    public func selectPlanCell(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(planCellIdentifier(name: plan.rawValue)).waitUntilExists().tap()
        return self
    }

    public func selectCurrentPlanCell(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(currentPlanCellIdentifier(name: plan.rawValue)).waitUntilExists().tap()
        return self
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
        staticText(name).waitUntilExists().checkExists()
        return self
    }

    @discardableResult
    public func verifyNumberOfPlansToPurchase(number: Int) -> PaymentsUIRobot {
        table("PaymentsUIViewController.tableView").waitUntilExists().checkExists()
        let count = XCUIApplication().tables.matching(identifier: "PaymentsUIViewController.tableView").cells.count
        XCTAssertEqual(count, number)
        return self
    }

    @discardableResult
    public func verifyTableCellStaticText(cellName: String, name: String) -> PaymentsUIRobot {
        table("PaymentsUIViewController.tableView").waitUntilExists().checkExists()
        let staticTexts = XCUIApplication().tables.matching(identifier: "PaymentsUIViewController.tableView").cells.matching(identifier: cellName).staticTexts
        XCTAssertTrue(staticTexts[name].exists)
        return self
    }

    @discardableResult
    public func verifyPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
        plan.getDescription.forEach {
            staticText($0).waitUntilExists().checkExists()
        }
        return self
    }

    @discardableResult
    public func verifyCurrentPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
       cell(currentPlanCellIdentifier(name: plan.rawValue)).waitUntilExists().checkExists()
       return self
   }

    @discardableResult
    public func verifyPlanV5(plan: PaymentsPlan) -> PaymentsUIRobot {
        plan.getDescriptionV5.forEach {
            staticText($0).waitUntilExists().checkExists()
        }
        return self
    }

    public func expandPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
        button(expandPlanButtonIdentifier(name: plan.rawValue)).waitUntilExists().tap()
        return self
    }

    @discardableResult
    public func verifyExpirationTime() -> PaymentsUIRobot {
        let expirationString = String(format: PUITranslations.plan_details_renew_expired.l10n, getEndDateString)
        staticText(expirationString).checkExists()
        return self
    }

    @discardableResult
    public func verifyRenewTime() -> PaymentsUIRobot {
        let expirationString = String(format: PUITranslations.plan_details_renew_auto_expired.l10n, getEndDateString)
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
        button(extendSubscriptionText).waitUntilExists().tap()
        return PaymentsUISystemRobot()
    }

    public func extendSubscriptionSelected() -> PaymentsUIRobot {
        button(extendSubscriptionText).checkExists().checkSelected()
        return PaymentsUIRobot()
    }

    @discardableResult
    public func verifyExtendButton() -> PaymentsUIRobot {
        button(extendSubscriptionText).waitUntilExists().checkExists()
        return self
    }

    @discardableResult
    public func verifyExtendDoesNotExists() -> PaymentsUIRobot {
        button(extendSubscriptionText).checkDoesNotExist()
        return self
    }

    public final class PaymentsUISystemRobot: CoreElements {

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

private extension Wait {
    func wait(timeInterval: TimeInterval) {
        let testCase = XCTestCase()
        let waitExpectation = testCase.expectation(description: "Waiting")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            waitExpectation.fulfill()
        }
        testCase.waitForExpectations(timeout: timeInterval + 0.5)
    }
}

#endif
