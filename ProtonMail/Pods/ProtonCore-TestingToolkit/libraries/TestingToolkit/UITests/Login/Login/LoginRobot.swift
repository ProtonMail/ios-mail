//
//  LoginRobot.swift
//  ProtonCore-TestingToolkit - Created on 11.02.2021.
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

import pmtest
import ProtonCore_CoreTranslation

private let titleId = "LoginViewController.titleLabel"
private let subtitleId = "LoginViewController.subtitleLabel"
private let loginViewCloseButtonId = "UINavigationItem.leftBarButtonItem"
private let errorBannerMessage = "Email address already used."
private let errorBannerButton = CoreString._hv_ok_button
private let loginTextFieldId = "LoginViewController.loginTextField.textField"
private let passwordTextFieldId = "LoginViewController.passwordTextField.textField"
private let signInButtonId = "LoginViewController.signInButton"
private let invalidCredentialText = "Incorrect login credentials. Please try again"
private let signUpButtonId = "LoginViewController.signUpButton"
private let helpButtonId = "LoginViewController.helpButton"
private let loginFieldTitleLabel = "LoginViewController.loginTextField.titleLabel"
private let passwordFieldTitleLabel = "LoginViewController.passwordTextField.titleLabel"
private let suspendedErrorText = "This account has been suspended due to a potential policy violation. If you believe this is in error, please contact us at https://proton.me/support/abuse"
private let textPredicate = NSPredicate(format: "label CONTAINS[c] %@", suspendedErrorText)
private let textChangePassword = "Change your password"
private let buttonChangePasswordCancel = "Cancel"
private let buttonChangePassword = "Change password"

public final class LoginRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        
        @discardableResult
        public func loginScreenIsShown() -> LoginRobot {
            staticText(titleId).wait().checkExists()
            staticText(subtitleId).wait().checkExists()
            return LoginRobot()
        }

        @discardableResult
        public func switchToCreateAccountButtonIsShown() -> LoginRobot {
            button(signUpButtonId).wait().checkExists()
            return LoginRobot()
        }

        @discardableResult
        public func switchToCreateAccountButtonIsNotPresented() -> LoginRobot {
            button(signUpButtonId).wait().checkDoesNotExist()
            return LoginRobot()
        }
        
        @discardableResult
        public func checkEmail(email: String) -> LoginRobot {
            textField(loginTextFieldId).tap().checkHasValue(email)
            return LoginRobot()
        }
        
        @discardableResult
        public func emailAlreadyExists() -> LoginRobot {
            LoginRobot().textView(errorBannerMessage).wait().checkExists()
            LoginRobot().button(errorBannerButton).tap()
            return LoginRobot()
        }
        
        public func incorrectCredentialsErrorDialog() {
            textView(invalidCredentialText).wait(time: 20).checkExists()
        }
        
        public func suspendedErrorDialog() {
            textView(textPredicate).wait().checkExists()
        }
        
        public func changePassword() -> LoginRobot {
            staticText(textChangePassword).wait(time: 20).checkExists()
            return LoginRobot()
        }
        
        public func changePasswordCancel() -> LoginRobot {
            button(buttonChangePasswordCancel).wait(time: 20).checkExists()
            return LoginRobot()
        }
        
        public func changePasswordConfirm() {
            button(buttonChangePassword).wait(time: 20).checkExists()
        }
    }
    
    public func insertPassword(password: String) -> LoginRobot {
        secureTextField(passwordTextFieldId).tap().typeText(password)
        return self
    }
    
    public func signInButtonTapAfterEmailError<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(signInButtonId).tap()
        return Robot()
    }
    
    public func fillUsername(username: String) -> LoginRobot {
        textField(loginTextFieldId).tap().typeText(username)
        return self
    }
    
    public func fillEmail(email: String) -> LoginRobot {
        textField(loginTextFieldId).tap().typeText(email)
        return self
    }
    
    public func fillpassword(password: String) -> LoginRobot {
        secureTextField(passwordTextFieldId).tap().wait().typeText(password)
        return self
    }
    
    public func signIn<T: CoreElements>(robot _: T.Type) -> T {
        button(signInButtonId).tap()
        return T()
    }
    
    public func signInElementsDisplayed() {
        button(loginViewCloseButtonId).wait().checkExists()
        staticText(titleId).checkExists()
        staticText(loginFieldTitleLabel).checkExists()
        staticText(passwordFieldTitleLabel).checkExists()
        button(signUpButtonId).checkExists()
        button(helpButtonId).checkExists()
    }
    
    public func switchToCreateAccount() -> SignupRobot {
        button(signUpButtonId).tap()
        return SignupRobot()
    }
    
    public func needHelp() -> NeedHelpRobot {
        button(helpButtonId).tap()
        return NeedHelpRobot()
    }
    
    public func closeLoginScreen<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(loginViewCloseButtonId).tap()
        return Robot()
    }
}
