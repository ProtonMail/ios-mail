//
//  AccountSwitcherRobot.swift
//  ProtonCore-TestingToolkit - Created on 16.04.21.
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
import ProtonCoreHumanVerification
import fusion

private let humanVerificationScreenIdentifier = "Human Verification view"
private let closeButtonAccessibilityId = "closeButton"
private let emailButton = HVTranslation.email_method_name.l10n
private let smsButton = HVTranslation.sms_method_name.l10n
private let captchaButton = HVTranslation.captha_method_name.l10n

public final class HumanVerificationRobot: CoreElements {

    public let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> HumanVerificationRobot {
            otherElement(humanVerificationScreenIdentifier).waitUntilExists().checkExists()
            return HumanVerificationRobot()
        }
    }

    public func emailTab() -> HumanVerificationRobot {
        button(emailButton).waitUntilExists().tap()
        return HumanVerificationRobot()
    }

    public func smsTab() -> HumanVerificationRobot {
        button(smsButton).waitUntilExists().tap()
        return HumanVerificationRobot()
    }

    public func captchaTab() -> HumanVerificationRobot {
        button(captchaButton).waitUntilExists().tap()
        return HumanVerificationRobot()
    }

    public enum CaptchaType: String {
        case recaptcha = "Recaptcha requires verification. I'm not a robot"
        case hCaptcha = "hCaptcha checkbox. Select in order to trigger the challenge, or to bypass it if you have an accessibility cookie."
    }

    @discardableResult
    public func captchaTap() -> HumanVerificationRobot {
        captchaTap(captcha: .recaptcha, to: HumanVerificationRobot.self)
    }

    @discardableResult
    public func captchaTap<Robot: CoreElements>(captcha: CaptchaType, to: Robot.Type) -> Robot {
        let element = XCUIApplication().webViews.webViews.switches[captcha.rawValue]
        Wait().forElement(element, #file, #line) // #, 10) <- this timeout option is not on PMTestAutomation
        element.tap()
        return Robot()
    }

    @discardableResult
    public func close<Robot: CoreElements>(to _: Robot.Type) -> Robot {
        button(closeButtonAccessibilityId).waitUntilExists().tap()
        return Robot()
    }
}

#endif
