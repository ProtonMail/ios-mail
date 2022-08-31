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

import XCTest
import ProtonCore_CoreTranslation
import pmtest

private let humanVerificationScreenIdentifier = "Human Verification view"
private let closeButtonAccessibilityId = "closeButton"
private let emailButton = CoreString._hv_email_method_name
private let smsButton = CoreString._hv_sms_method_name
private let captchaButton = CoreString._hv_captha_method_name
private let recaptchaButtonCheck = "Recaptcha requires verification. I'm not a robot"

public final class HumanVerificationRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> HumanVerificationRobot {
            otherElement(humanVerificationScreenIdentifier).wait().checkExists()
            return HumanVerificationRobot()
        }
    }
    
    public func emailTab() -> HumanVerificationRobot {
        button(emailButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    public func smsTab() -> HumanVerificationRobot {
        button(smsButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    public func captchaTab() -> HumanVerificationRobot {
        button(captchaButton).wait().tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    public func captchaTap() -> HumanVerificationRobot {
        let element = XCUIApplication().webViews.webViews.switches[recaptchaButtonCheck]
        Wait().forElement(element, #file, #line) // #, 10) <- this timeout option is not on PMTestAutomation
        element.tap()
        return HumanVerificationRobot()
    }
    
    @discardableResult
    public func close<Robot: CoreElements>(to _: Robot.Type) -> Robot {
        button(closeButtonAccessibilityId).wait().tap()
        return Robot()
    }
    
}
