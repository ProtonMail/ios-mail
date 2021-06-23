//
//  PasswordRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 18.04.21.
//

import Foundation
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "PasswordViewController.createPasswordTitleLabel"
private let passwordNameTextFieldId = "PasswordViewController.passwordTextField.textField"
private let repeatPasswordNameTextFieldId = "PasswordViewController.repeatPasswordTextField.textField"
private let nextButtonId = "PasswordViewController.nextButton"
private let errorBannerPassEmpty = CoreString._su_error_password_empty
private let errorBannerPassTooShort = String(format: CoreString._su_error_password_too_short, NSNumber(8))
private let errorBannerPassNotEqual = CoreString._su_error_password_not_equal
private let errorBannerButton = CoreString._hv_ok_button
private let backtButtonName = "Back"

public final class PasswordRobot: CoreElements {

    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func passwordScreenIsShown() -> PasswordRobot {
            staticText(titleId).wait().checkExists()
            return PasswordRobot()
        }

        @discardableResult
        public func passwordEmpty() -> PasswordRobot {
            textView(errorBannerPassEmpty).wait().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }

        @discardableResult
        public func passwordTooShort() -> PasswordRobot {
            textView(errorBannerPassTooShort).wait().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }
        
        @discardableResult
        public func passwordNotEqual() -> PasswordRobot {
            textView(errorBannerPassNotEqual).wait().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }
    }
    
    public func insertPassword(password: String) -> PasswordRobot {
        secureTextField(passwordNameTextFieldId).tap().typeText(password)
        return self
    }
    
    public func clearPassword() -> PasswordRobot {
        _ = secureTextField(passwordNameTextFieldId).tap().clearText()
        return self
    }

    public func insertRepeatPassword(password: String) -> PasswordRobot {
        secureTextField(repeatPasswordNameTextFieldId).tap().typeText(password)
        return self
    }
    
    public func nextButtonTap<T: CoreElements>(robot _: T.Type) -> T {
        button(nextButtonId).tap()
        return T()
    }
}
