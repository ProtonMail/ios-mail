//
//  SignupHumanVerificationV3Robot.swift
//  ProtonCore-TestingToolkit - Created on 13.12.2021
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

import Foundation
import XCTest
import pmtest
import ProtonCore_CoreTranslation

private let humanVerificationScreenIdentifier = "Human Verification view"
private let hCaptchaButtonCheckName = "hCaptcha checkbox. Select in order to trigger the challenge, or to bypass it if you have an accessibility cookie."
private let closeButtonAccessibilityId = "closeButton"
private let captchaSelectedControlLabel = CoreString._hv_captha_method_name
private let smsSelectedControlLabel = CoreString._hv_sms_method_name
private let emailSelectedControlLabel = CoreString._hv_email_method_name
private let emailTextField = "EmailVerifyViewController.emailTextFieldView.textField"
private let sendCodeButtonLabel = CoreString._hv_email_verification_button
private let verifyCodeTextField = "VerifyCodeViewController.verifyCodeTextFieldView.textField"
private let verifyCodeButtonLabel = CoreString._hv_verification_verify_button
private let verifyEmailButtonLabel = "Verify email"
private let didntReceiveCodeButtonLabel = "Didn't receive the code?"
private let editEmailAddressButtonLabel = "Edit email address"
private let requestNewCodeButtonLabel = "Request new code"
private let resendCodeLabel = "Code sent to %@"

public final class SignupHumanVerificationV3Robot: CoreElements {
    public enum HV3OrCompletionRobot {
        case humanVerification(SignupHumanVerificationV3Robot)
        case complete(CompleteRobot)

        public func proceed<T: CoreElements>(email: String, code: String, to: T.Type) -> T {
            switch self {
            case .humanVerification(let hvRobot):
                return hvRobot
                    .verify.humanVerificationScreenIsShown()
                    .performEmailVerificationV3(email: email, code: code, to: CompleteRobot.self)
                    .verify.completeScreenIsShown(robot: T.self)
            case .complete(let completeRobot):
                return completeRobot
                    .verify.completeScreenIsShown(robot: T.self)
            }
        }
    }
    
    public let verify = Verify()
    
    public func resendDialogDisplay(email: String) -> SignupHumanVerificationV3Robot {
        return verify.resendEmailDialogShown(email: email)
    }
    
    public final class Verify: CoreElements {
        @discardableResult
        public func humanVerificationScreenIsShown() -> SignupHumanVerificationV3Robot {
            otherElement(humanVerificationScreenIdentifier).wait(time: 15).checkExists()
            return SignupHumanVerificationV3Robot()
        }
        
        public func isHumanVerificationRequired() -> HV3OrCompletionRobot {
            let humanVerificationScreen = XCUIApplication().otherElements[humanVerificationScreenIdentifier]
            Wait(time: 10.0).forElement(humanVerificationScreen)
            return humanVerificationScreen.exists ? .humanVerification(SignupHumanVerificationV3Robot()) : .complete(CompleteRobot())
        }
        
        public func resendEmailDialogShown(email: String) -> SignupHumanVerificationV3Robot {
            let messageName = String(format: resendCodeLabel, email)
            staticText(messageName).wait().checkExists()
            return SignupHumanVerificationV3Robot()
        }
    }
    
    public func switchToEmailHVMethod() -> SignupHumanVerificationV3Robot {
        button(emailSelectedControlLabel).tap()
        return self
    }
    
    public func insertEmailV3(_ email: String) -> SignupHumanVerificationV3Robot {
        let element = XCUIApplication().webViews["HumanVerifyV3ViewController.webView"].webViews.textFields.element(boundBy: 0)
        Wait().forElement(element)
        element.tap()
        element.typeText(email)
        return self
    }
    
    public func sendCodeButton() -> SignupHumanVerificationV3Robot {
        button(sendCodeButtonLabel).tap()
        return self
    }
    
    public func fillInCodeV3(_ code: String) -> SignupHumanVerificationV3Robot {
        let element = XCUIApplication().webViews["HumanVerifyV3ViewController.webView"].webViews.textFields.element(boundBy: 0)
        Wait().forElement(element)
        element.tap()
        element.typeText(code)
        return self
    }
    
    public func verifyCodeButton<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(verifyCodeButtonLabel).wait(time: 30).tap()
        return Robot()
    }
    
    public func verifyEmailButton<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(verifyEmailButtonLabel).wait(time: 30).tap()
        return Robot()
    }
    
    public func didntReceiveCodeButton() -> SignupHumanVerificationV3Robot {
        button(didntReceiveCodeButtonLabel).wait(time: 30).tap()
        return SignupHumanVerificationV3Robot()
    }
    
    public func editEmailAddressButton<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(editEmailAddressButtonLabel).wait(time: 30).tap()
        return Robot()
    }
    
    public func requestNewCodeButton<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(requestNewCodeButtonLabel).wait(time: 30).tap()
        return Robot()
    }
    
    public func performEmailVerificationV3<Robot: CoreElements>(
        email: String, code: String, to: Robot.Type
    ) -> Robot {
        self
            .switchToEmailHVMethod()
            .insertEmailV3(email)
            .sendCodeButton()
            .fillInCodeV3(code)
            .verifyCodeButton(to: Robot.self)
    }
    
    public func performOwnershipEmailVerificationV3<Robot: CoreElements>(code: String, to: Robot.Type
    ) -> Robot {
        self
            .fillInCodeV3(code)
            .verifyEmailButton(to: Robot.self)
    }

    public func humanVerificationCaptchaTap<Robot: CoreElements>(to: Robot.Type) -> Robot {
        let element = XCUIApplication().webViews["RecaptchaViewController.webView"].webViews.switches[hCaptchaButtonCheckName]
        Wait().forElement(element)
        element.tap()
        return Robot()
    }
    
    public func closeButton() -> RecoveryRobot {
        button(closeButtonAccessibilityId).tap()
        return RecoveryRobot()
    }
}
