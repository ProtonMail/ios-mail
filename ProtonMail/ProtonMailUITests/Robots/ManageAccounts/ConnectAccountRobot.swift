//
//  ConnectAccountRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let usernameTextFieldIdentifier = "AccountConnectViewController.usernameTextField"
    static let passwordSecureTextFieldIdentifier = "AccountConnectViewController.passwordTextField"
    static let loginButtonIdentifier = "AccountConnectViewController.signInButton"
    static let mailboxPasswordTextField = "AccountPasswordViewController.passwordTextField"
    static let decryptButtonIdentifier = "AccountPasswordViewController.signInButton"
    static let twoFaCodeIdentifier = "TwoFACodeViewController.twoFactorCodeField"
    static let twoFaEnterButtonIdentifier = "TwoFACodeViewController.enterButton"
    static let twoFaCancelButtonIdentifier = "TwoFACodeViewController.cancelButton"
    static let cancelButtonIdentifier = "UINavigationItem.leftBarButtonItem"
    static let limitReachedText = LocalString._free_account_limit_reached_title
}

class ConnectAccountRobot: CoreElements {
    
    var verify = Verify()
    
    func connectOnePassAccount(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signIn()
    }

    func connectOnePassAccountWithTwoFa(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFa()
    }

    func connectTwoPassAccount(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .mailboxPassword(user.mailboxPassword)
            .decrypt()
    }

    func connectTwoPassAccountWithTwoFa(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFaAndProvideMailboxPassword()
            .mailboxPassword(user.mailboxPassword)
            .decrypt()
    }

    func connectSecondFreeOnePassAccountWithTwoFa(_ user: User) -> ConnectAccountRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .twoFaCode(user.getTwoFaCode())
            .confirmTwoFaWithReachedLimit()
    }

    func cancelLoginOnTwoFaPrompt(_ user: User) -> InboxRobot {
        return username(user.email)
            .password(user.password)
            .signInWithMailboxPasswordOrTwoFa()
            .cancelTwoFaPrompt()
            .cancelAccountAdding()
    }

    private func signIn() -> InboxRobot {
        button(id.loginButtonIdentifier).tap()
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
        button(id.twoFaCancelButtonIdentifier).tap()
        return ConnectAccountRobot()
    }

    private func cancelAccountAdding() -> InboxRobot {
        button(id.cancelButtonIdentifier).tap()
        return InboxRobot()
    }

    private func username(_ username: String) -> ConnectAccountRobot {
        textField(id.usernameTextFieldIdentifier).tap().typeText(username)
        return self
    }

    private func password(_ password: String) -> ConnectAccountRobot {
        secureTextField(id.passwordSecureTextFieldIdentifier).tap().typeText(password)
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
        button(id.loginButtonIdentifier).tap()
        return self
    }

    /**
     * Contains all the validations that can be performed by [ConnectAccountRobot].
     */
    class Verify: CoreElements {

        func limitReachedDialogDisplayed() {
            staticText().wait().checkExists()
        }
    }
}
