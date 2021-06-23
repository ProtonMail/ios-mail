//
//  LoginRobot.swift
//  SampleAppUITests
//
//  Created by denys zelenchuk on 11.02.21.
//
import pmtest
import ProtonCore_CoreTranslation

private let titleId = "LoginViewController.titleLabel"
private let subtitleId = "LoginViewController.subtitleLabel"
private let loginViewCloseButtonId = "LoginViewController.closeButton"
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
private let suspendedErrorText = "This account has been suspended due to a potential policy violation."
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
    
    public func fillUsername(username: String )  -> LoginRobot {
        textField(loginTextFieldId).tap().typeText(username)
        return self
    }
    
    public func fillEmail(email: String )  -> LoginRobot {
        textField(loginTextFieldId).tap().typeText(email)
        return self
    }
    
    public func fillpassword(password: String)  -> LoginRobot {
        secureTextField(passwordTextFieldId).tap().typeText(password)
        return self
    }
    
    public func signIn<T: CoreElements>(robot _: T.Type) -> T {
        button(signInButtonId).tap().wait(time: 55)
        return T()
    }
    
    public func signInElementsDisplayed() {
        button(loginViewCloseButtonId).checkExists()
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
