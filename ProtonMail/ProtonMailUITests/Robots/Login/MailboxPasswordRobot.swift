//
//  MailboxPasswordRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 12.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let mailboxPasswordTextField = "MailboxPasswordViewController.passwordTextField"
private let decryptButton = "MailboxPasswordViewController.decryptButton"
private let decryptFailedStaticTextIdentifier = LocalString._the_mailbox_password_is_incorrect

class MailboxPasswordRobot {
    
    func decryptMailbox(_ mailboxPwd: String) -> InboxRobot {
        return mailboxPassword(mailboxPwd)
            .decrypt()
    }

    private func mailboxPassword(_ mailboxPwd: String) -> MailboxPasswordRobot {
        Element.wait.forSecureTextFieldWithIdentifier(mailboxPasswordTextField, file: #file, line: #line).typeText(mailboxPwd)
        return self
    }
    
    private func decrypt() -> InboxRobot {
        Element.button.tapByIdentifier(decryptButton)
        return InboxRobot()
    }
    
    func decryptMailboxWithInvalidPassword(_ mailboxPwd: String) -> ErrorDialogRobot {
        let incorrectPwd = "wrong" + mailboxPwd
        return mailboxPassword(incorrectPwd)
            .decryptWithWrongPassword()
    }
    
    private func decryptWithWrongPassword() -> ErrorDialogRobot {
        Element.button.tapByIdentifier(decryptButton)
        return ErrorDialogRobot()
    }
    
    class ErrorDialogRobot {
        
        var verify: Verify! = nil
        init() { verify = Verify() }
        
        class Verify {
            
            func verifyDecryptFailedErrorDisplayed() {
                Element.wait.forStaticTextFieldWithIdentifier(decryptFailedStaticTextIdentifier, file: #file, line: #line)
            }
            
        }
    }
}
