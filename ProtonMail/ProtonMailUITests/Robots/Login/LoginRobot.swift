//
//  LoginRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import PMTestAutomation

fileprivate struct id {
    static let usernameIdentifier = "SignInViewController.usernameTextField"
    static let passwordIdentifier = "SignInViewController.passwordTextField"
    static let signinButtonIdentifier = "SignInViewController.signInButton"
    static let twoFaCodeIdentifier = "TwoFACodeViewController.twoFactorCodeField"
    static let twoFaCancelButtonIdentifier = "TwoFACodeViewController.cancelButton"
    static let twoFaEnterButtonIdentifier = "TwoFACodeViewController.enterButton"
    static let invalidCredentialStaticTextIdentifier = "Incorrect login credentials. Please try again"
}
    
class LoginRobot: CoreElements {
    
    var verify = Verify()
    
    @discardableResult
    func loginUser(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signIn()
    }

    func loginUserWithTwoFA(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithTwoFA()
            .provideTwoFaCode(code: user.getTwoFaCode())
    }

    func loginTwoPasswordUser(_ user: User) -> MailboxPasswordRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPassword()
    }

    func loginTwoPasswordUserWithTwoFA(_ user: User) -> MailboxPasswordRobot {
        return username(user.email)
            .password(user.password)
            .signInWithTwoFA()
            .provideTwoFaCodeMailbox(code: user.getTwoFaCode())
    }
    
    func loginWithInvalidUser(_ user: User) -> ErrorDialogRobot {
        let incorrectEmail = "invalid" + user.email
        return username(incorrectEmail)
            .password(user.password)
            .singInWithInvalidCreadential()
    }
    
    func loginWithInvalidUserAndPassword(_ user: User) -> ErrorDialogRobot {
        let email = "invalid" + user.email
        let password = "invalid" + user.password
        return username(email)
            .password(password)
            .singInWithInvalidCreadential()
    }
    
    func loginWithInvalidPassword(_ user: User) -> ErrorDialogRobot {
        let invalidPassword = "invalid" + user.password
        return username(user.email)
            .password(invalidPassword)
            .singInWithInvalidCreadential()
    }
    
    private func username(_ username: String) -> LoginRobot {
        textField(id.usernameIdentifier).typeText(username)
        return self
    }
    
    private func password(_ password: String) -> LoginRobot {
        secureTextField(id.passwordIdentifier).tap().typeText(password)
        return self
    }
    
    private func signIn() -> InboxRobot {
        button(id.signinButtonIdentifier).tap()
        return InboxRobot()
    }
    
    private func signInWithMailboxPassword() -> MailboxPasswordRobot {
        button(id.signinButtonIdentifier).tap()
        return MailboxPasswordRobot()
    }
    
    private func signInWithTwoFA() -> TwoFaRobot {
        button(id.signinButtonIdentifier).tap()
        return TwoFaRobot()
    }
    
    private func singInWithInvalidCreadential() -> ErrorDialogRobot {
        button(id.signinButtonIdentifier).tap()
        return ErrorDialogRobot()
    }
    
    private func secondPass(mailboxPassword: String) -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func confirmSecondPass() -> LoginRobot {
        //TODO:: add implementation
        return self
    }
    
    class ErrorDialogRobot {
        
        var verify: Verify! = nil
        init() { verify = Verify() }
        
        class Verify: CoreElements {
            func invalidCredentialDialogDisplay() {
                staticText(id.invalidCredentialStaticTextIdentifier).wait().checkExists()
            }
        }
    }
    
    class TwoFaRobot: CoreElements {

        func provideTwoFaCode(code: String) -> InboxRobot {
            twoFACode(code: code)
                .confirm2FA()
            return InboxRobot()
        }

        func provideTwoFaCodeMailbox(code: String) -> MailboxPasswordRobot {
            twoFACode(code: code)
                .confirm2FA()
            return MailboxPasswordRobot()
        }

        private func confirm2FA() {
            button(id.twoFaEnterButtonIdentifier).tap()
        }
        
        private func twoFACode(code: String) -> TwoFaRobot {
            textField(id.twoFaCodeIdentifier).typeText(code)
            return self
        }
    }
    
    class Verify: CoreElements {
        
        func loginScreenDisplayed() {
            button(id.signinButtonIdentifier).wait().checkExists()
        }
    }
}
