//
//  EmailVerificationRobot.swift
//  ProtonCore-TestingToolkit - Created on 19.04.2021.
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
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "EmailVerificationViewController.emailVerificationTitleLabel"
private let verificationCodeTextField = "EmailVerificationViewController.verificationCodeTextField.textField"
private let nextButtonId = "EmailVerificationViewController.nextButton"
private let resendCodeButtonId = "EmailVerificationViewController.notReceivedCodeButton"
private let bannerSendMessage = CoreString._hv_verification_sent_banner
private let verificationDialogTitleName = "Invalid verification code"
private let verificationDialogMessageName = CoreString._su_invalid_verification_alert_message
private let verificationDialogResendButtonAccessibility = "resendButton"
private let verificationDialogChangeEmailButtonAccessibility = "changeEmailButton"
private let resendDialogTitleName = CoreString._hv_verification_new_alert_title
private let resendDialogNewCodeButtonAccessibility = "newCodeButton"
private let resendDialogCancelButtonAccessibility = "cancelButton"

public class EmailVerificationRobot: CoreElements {

    public let verify = Verify()
    
    public class Verify: CoreElements {
        @discardableResult
        public func emailVerificationScreenIsShown() -> EmailVerificationRobot {
            staticText(titleId).wait().checkExists()
            return EmailVerificationRobot()
        }
        
        @discardableResult
        public func resendEmailMessage(email: String) -> EmailVerificationRobot {
            let msg = String(format: bannerSendMessage, email)
            textView(msg).wait().checkExists()
            return EmailVerificationRobot()
        }
        
        @discardableResult
        public func verifyVerificationCode(code: String) -> EmailVerificationRobot {
            textField(verificationCodeTextField).tap().checkHasValue(code)
            return EmailVerificationRobot()
        }
    }
    
    public func insertCode(code: String) -> EmailVerificationRobot {
        textField(verificationCodeTextField).tap().typeText(code)
        return self
    }
    
    public func nextButtonTap<T: CoreElements>(robot _: T.Type) -> T {
        button(nextButtonId).tap()
        return T()
    }
    
    public func waitDisapper() -> SignupRobot {
        button(nextButtonId).waitUntilGone()
        return SignupRobot()
    }
    
    public func resendCodeButton() -> ResendDialogRobot {
        button(resendCodeButtonId).tap()
        return ResendDialogRobot()
    }
    
    public final class EmailVerificationDialogRobot: CoreElements {
        
        public let verify = Verify()
        
        public final class Verify: CoreElements {
            @discardableResult
            public func verificationDialogDisplay() -> EmailVerificationDialogRobot {
                staticText(verificationDialogTitleName).wait().checkExists()
                staticText(verificationDialogMessageName).wait().checkExists()
                return EmailVerificationDialogRobot()
            }
        }

        @discardableResult
        public func changeEmailButtonTap() -> EmailVerificationRobot {
            button(verificationDialogChangeEmailButtonAccessibility).tap()
            return EmailVerificationRobot()
        }
        
        @discardableResult
        public func resendButtonTap() -> EmailVerificationRobot {
            button(verificationDialogResendButtonAccessibility).tap()
            return EmailVerificationRobot()
        }
    }
    
    public final class ResendDialogRobot: CoreElements {
        public let verify = Verify()

        public final class Verify: CoreElements {
            @discardableResult
            public func resendDialogDisplay(email: String) -> ResendDialogRobot {
                let messageName = String(format: CoreString._hv_verification_new_alert_message, email)
                staticText(resendDialogTitleName).wait().checkExists()
                staticText(messageName).wait().checkExists()
                return ResendDialogRobot()
            }
        }
        
        @discardableResult
        public func newCodeButtonTap() -> EmailVerificationRobot {
            button(resendDialogNewCodeButtonAccessibility).tap()
            return EmailVerificationRobot()
        }
        
        @discardableResult
        public func cancelButtonTap() -> EmailVerificationRobot {
            button(resendDialogCancelButtonAccessibility).tap()
            return EmailVerificationRobot()
        }
    }
}
