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

class LoginRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify(parent: self) }
    
    func loginUser(_ name: String, _ pwd: String) -> InboxRobot {
        return username(name)
            .password(pwd)
            .signIn()
    }

    func loginUserWithTwoFA(user: String) -> LoginRobot {
        return username(user)
            .password(user)
            .signInWithTwoFA()
            .twoFACode(twoFACode: user)
            .confirm2FA()
    }

    func loginTwoPasswordUser(user: User) -> MailboxPasswordRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPassword()
    }

    private func loginTwoPasswordUserWithTwoFA(user: String) -> LoginRobot {
        return username(user)
            .password(user)
            .twoFACode(twoFACode: user)
            .mailboxPassword(password: user)
            .decrypt()
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
    
    private func signInWithTwoFA() -> LoginRobot {
        Element.button.tapByIdentifier(signinButtonIdentifier)
        return LoginRobot()
    }
    
    private func loginUserWithTwoFA() -> InboxRobot {
        Element.button.tapByIdentifier(signinButtonIdentifier)
        return InboxRobot()
    }
    
    private func mailboxPassword(password: String?) -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func decrypt() -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func confirm2FA() -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func twoFACode(twoFACode: String?) -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func secondPass(mailboxPassword: String) -> LoginRobot {
        //TODO:: add implementation
        return self
    }

    private func confirmSecondPass() -> LoginRobot {
        //TODO:: add implementation
        return self
    }
    
    class Verify {
        unowned let loginRobot: LoginRobot
        init(parent: LoginRobot) { loginRobot = parent }

        func loginViewShown() {
            Element.assert.buttonWithIdentifierExists(signinButtonIdentifier, file: #file, line: #line)
        }
    }
}
