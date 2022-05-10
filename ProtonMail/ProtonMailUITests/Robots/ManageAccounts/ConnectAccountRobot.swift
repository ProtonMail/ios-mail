//
//  ConnectAccountRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let usernameTextFieldIdentifier = "LoginViewController.loginTextField.textField"
    static let passwordSecureTextFieldIdentifier = "LoginViewController.passwordTextField.textField"
    static let loginButtonIdentifier = "LoginViewController.signInButton"
    static let mailboxPasswordTextField = "MailboxPasswordViewController.mailboxPasswordTextField.textField"
    static let decryptButtonIdentifier = "MailboxPasswordViewController.unlockButton"
    static let twoFaCodeIdentifier = "TwoFactorViewController.codeTextField.textField"
    static let twoFaEnterButtonIdentifier = "TwoFactorViewController.authenticateButton"
    static let cancelButtonIdentifier = "UINavigationItem.leftBarButtonItem"
    static let limitReachedText = LocalString._free_account_limit_reached_title
}

class ConnectAccountRobot: CoreElements {
    
    var verify = Verify()
    
    func connectOnePassAccount(_ user: User) -> InboxRobot {
        return username(user.name)
            .password(user.password)
            .signIn()
    }

    func connectOnePassAccountWithTwoFa(_ user: User) -> InboxRobot {
        return username(user.name)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFa()
    }

    func connectTwoPassAccount(_ user: User) -> InboxRobot {
        return username(user.name)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .mailboxPassword(user.mailboxPassword)
            .decrypt()
    }

    func connectTwoPassAccountWithTwoFa(_ user: User) -> InboxRobot {
        return username(user.name)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFaAndProvideMailboxPassword()
            .mailboxPassword(user.mailboxPassword)
            .decrypt()
    }

    func connectSecondFreeOnePassAccountWithTwoFa(_ user: User) -> ConnectAccountRobot {
        return username(user.name)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFaWithReachedLimit()
    }

    func cancelLoginOnTwoFaPrompt(_ user: User) -> AccountManagerRobot {
        return username(user.name)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .cancelTwoFaPrompt()
            .closeSignInScreen()
    }

    private func signIn() -> InboxRobot {
        button(id.loginButtonIdentifier).firstMatch().tap()
        return InboxRobot()
    }
    
    private func decrypt() -> InboxRobot {
        button(id.decryptButtonIdentifier).tap()
        return InboxRobot()
    }

    private func confirmTwoFa() -> InboxRobot {
        button(id.twoFaEnterButtonIdentifier).tap()
        return InboxRobot()
    }
    
    private func confirmTwoFaAndProvideMailboxPassword() -> ConnectAccountRobot {
        button(id.twoFaEnterButtonIdentifier).tap()
        return self
    }

    private func confirmTwoFaWithReachedLimit() -> ConnectAccountRobot {
        button(id.twoFaEnterButtonIdentifier).tap()
        return ConnectAccountRobot()
    }

    private func cancelTwoFaPrompt() -> ConnectAccountRobot {
        button(id.cancelButtonIdentifier).tap()
        return ConnectAccountRobot()
    }

    private func closeSignInScreen() -> AccountManagerRobot {
        button(id.cancelButtonIdentifier).tap()
        return AccountManagerRobot()
    }

    private func username(_ username: String) -> ConnectAccountRobot {
        textField(id.usernameTextFieldIdentifier).firstMatch().tap().typeText(username)
        return self
    }

    private func password(_ password: String) -> ConnectAccountRobot {
        secureTextField(id.passwordSecureTextFieldIdentifier).firstMatch().tap().typeText(password)
        return self
    }

    private func mailboxPassword(_ mailboxPwd: String) -> ConnectAccountRobot {
        secureTextField(id.mailboxPasswordTextField).tap().typeText(mailboxPwd)
        return self
    }

    private func twoFaCode(_ code: String) -> ConnectAccountRobot {
        textField(id.twoFaCodeIdentifier).typeText(code)
        return self
    }
    
    private func confirm2FA() {
        button(id.twoFaEnterButtonIdentifier).tap()
    }
    
    private func signInWithMailboxPasswordOrTwoFa() -> ConnectAccountRobot {
        button(id.loginButtonIdentifier).firstMatch().tap()
        return self
    }

    /**
     * Contains all the validations that can be performed by [ConnectAccountRobot].
     */
    class Verify: CoreElements {

        /// Free users limit alert is shown.
        func limitReachedDialogDisplayed() {
            staticText(id.limitReachedText).wait().checkExists()
        }
    }
}
