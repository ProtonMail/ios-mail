//
//  SignupHumanVerificationRobot.swift
//  ProtonCore-TestingToolkit - Created on 19.04.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let titleName = CoreString._hv_title
private let recaptchaButtonCheckName = "Recaptcha requires verification. I'm not a robot"
private let closeButtonAccessibilityId = "closeButton"

public final class SignupHumanVerificationRobot: CoreElements {
    public enum HVOrCompletionRobot {
        case humanVerification(SignupHumanVerificationRobot)
        case complete(CompleteRobot)

        public func proceed<T: CoreElements>(to: T.Type) -> T {
            switch self {
            case .humanVerification(let hvRobot):
                return hvRobot
                    .verify.humanVerificationScreenIsShown()
                    .humanVerificationReCaptchaTap(to: CompleteRobot.self)
                    .verify.completeScreenIsShown(robot: T.self)
            case .complete(let completeRobot):
                return completeRobot
                    .verify.completeScreenIsShown(robot: T.self)
            }
        }
    }
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> SignupHumanVerificationRobot {
            staticText(titleName).wait().checkExists()
            return SignupHumanVerificationRobot()
        }
        
        public func isHumanVerificationRequired() -> HVOrCompletionRobot {
            let staticText = XCUIApplication().staticTexts[titleName]
            Wait(time: 5.0).forElement(staticText)
            return staticText.exists ? .humanVerification(SignupHumanVerificationRobot()) : .complete(CompleteRobot())
        }
    }

    public func humanVerificationCaptchaTap<Robot: CoreElements>(to: Robot.Type) -> Robot {
        let element = XCUIApplication().webViews["RecaptchaViewController.webView"].webViews.switches["0"]
        Wait().forElement(element)
        element.tap()
        return Robot()
    }
    
    //TODO remove it once recaptcha is changed to hCaptcha on all environments
    public func humanVerificationReCaptchaTap<Robot: CoreElements>(to: Robot.Type) -> Robot {
        let element = XCUIApplication().webViews["RecaptchaViewController.webView"].webViews.switches[recaptchaButtonCheckName]
        Wait().forElement(element)
        element.tap()
        return Robot()
    }
    
    public func closeButton() -> RecoveryRobot {
        button(closeButtonAccessibilityId).tap()
        return RecoveryRobot()
    }
}
