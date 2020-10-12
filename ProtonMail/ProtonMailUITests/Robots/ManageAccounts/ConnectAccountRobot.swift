//
//  ConnectAccountRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let usernameTextFieldIdentifier = "AccountConnectViewController.usernameTextField"
fileprivate let passwordSecureTextFieldIdentifier = "AccountConnectViewController.passwordTextField"
fileprivate let loginButtonIdentifier = "AccountConnectViewController.signInButton"
fileprivate let mailboxPasswordTextField = "AccountPasswordViewController.passwordTextField"
fileprivate let decryptButtonIdentifier = "AccountPasswordViewController.signInButton"
private let twoFaCodeIdentifier = "TwoFACodeViewController.twoFactorCodeField"
private let twoFaEnterButtonIdentifier = "TwoFACodeViewController.enterButton"
private let twoFaCancelButtonIdentifier = "TwoFACodeViewController.cancelButton"
private let cancelButtonIdentifier = "UINavigationItem.leftBarButtonItem"

class ConnectAccountRobot {
    
    var verify: Verify! = nil
    
    init() {
        verify = Verify()
    }
    
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
        Element.wait.forButtonWithIdentifier(loginButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }
    
    private func decrypt() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(decryptButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }

    private func confirmTwoFa() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(twoFaEnterButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }
    
    private func confirmTwoFaAndProvideMailboxPassword() -> ConnectAccountRobot {
        Element.wait.forButtonWithIdentifier(twoFaEnterButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    private func confirmTwoFaWithReachedLimit() -> ConnectAccountRobot {
        Element.wait.forButtonWithIdentifier(twoFaEnterButtonIdentifier, file: #file, line: #line).tap()
        return ConnectAccountRobot()
    }

    private func cancelTwoFaPrompt() -> ConnectAccountRobot {
        Element.wait.forButtonWithIdentifier(twoFaCancelButtonIdentifier, file: #file, line: #line).tap()
        return ConnectAccountRobot()
    }

    private func cancelAccountAdding() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(cancelButtonIdentifier, file: #file, line: #line).tap()
        return InboxRobot()
    }

    private func username(_ username: String) -> ConnectAccountRobot {
        Element.textField.tapByIdentifier(usernameTextFieldIdentifier).typeText(username)
        return self
    }

    private func password(_ password: String) -> ConnectAccountRobot {
        Element.secureTextField.tapByIdentifier(passwordSecureTextFieldIdentifier).typeText(password)
        return self
    }

    private func mailboxPassword(_ mailboxPwd: String) -> ConnectAccountRobot {
        Element.wait.forSecureTextFieldWithIdentifier(mailboxPasswordTextField, file: #file, line: #line)
            .click()
            .typeText(mailboxPwd)
        return self
    }

    private func twoFaCode(_ code: String) -> ConnectAccountRobot {
        Element.wait.forTextFieldWithIdentifier(twoFaCodeIdentifier, file: #file, line: #line).typeText(code)
        return self
    }
    
    private func confirm2FA() {
        Element.wait.forButtonWithIdentifier(twoFaEnterButtonIdentifier, file: #file, line: #line).tap()
    }
    
    private func signInWithMailboxPasswordOrTwoFa() -> ConnectAccountRobot {
        Element.button.tapByIdentifier(loginButtonIdentifier)
        return self
    }

    /**
     * Contains all the validations that can be performed by [ConnectAccountRobot].
     */
    class Verify {

        func limitReachedDialogDisplayed() {
            Element.wait.forStaticTextFieldWithIdentifier("Limit reached", file: #file, line: #line)
        }
    }
}
