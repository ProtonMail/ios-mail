//
//  LoginRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

private let usernameIdentifier = "txtUsername"
private let passwordIdentifier = "txtPassword"
private let signinButtonIdentifier = "loginButton"
private let twoFaCodeIdentifier = "TwoFACodeView"
private let twoFaCancelButtonIdentifier = "cancelButton"
private let twoFaEnterButtonIdentifier = "enterButton"

class LoginRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify(parent: self) }
    
    func loginUser(_ name: String, _ pwd: String) -> InboxRobot {
        return username(name)
            .password(pwd)
            .signIn()
    }

    func loginUserWithTwoFA(user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithTwoFA()
            .provideTwoFaCode(code: user.getTwoFaCode())
            
    }

    func loginTwoPasswordUser(user: User) -> MailboxPasswordRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPassword()
    }

    func loginTwoPasswordUserWithTwoFA(user: User) -> MailboxPasswordRobot {
        return username(user.email)
            .password(user.password)
            .signInWithTwoFA()
            .provideTwoFaCodeMailbox(code: user.getTwoFaCode())
    }
    
    private func username(_ username: String) -> LoginRobot {
        Element.textField.tapByIdentifier(usernameIdentifier).typeText(username)
        return self
    }
    
    private func password(_ password: String) -> LoginRobot {
        Element.secureTextField.tapByIdentifier(passwordIdentifier).typeText(password)
        return self
    }
    
    private func signIn() -> InboxRobot {
        Element.button.tapByIdentifier(signinButtonIdentifier)
        return InboxRobot()
    }
    
    private func signInWithMailboxPassword() -> MailboxPasswordRobot {
        Element.button.tapByIdentifier(signinButtonIdentifier)
        return MailboxPasswordRobot()
    }
    
    private func signInWithTwoFA() -> TwoFaRobot {
        Element.button.tapByIdentifier(signinButtonIdentifier)
        return TwoFaRobot()
    }

    private func secondPass(mailboxPassword: String) -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func confirmSecondPass() -> LoginRobot {
        //TODO:: add implementation
        return self
    }
    
    class TwoFaRobot {

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
            Element.wait.forButtonWithIdentifier(twoFaEnterButtonIdentifier).tap()
        }
        
        private func twoFACode(code: String) -> TwoFaRobot {
            Element.wait.forTextFieldWithIdentifier(twoFaCodeIdentifier).typeText(code)
            return self
        }
    }
    
    class Verify {
        unowned let loginRobot: LoginRobot
        init(parent: LoginRobot) { loginRobot = parent }

        func loginViewShown() {
            Element.assert.buttonWithIdentifierExists(signinButtonIdentifier, file: #file, line: #line)
        }
    }
}
