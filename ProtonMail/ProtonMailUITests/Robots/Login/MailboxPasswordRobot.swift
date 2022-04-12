//
//  MailboxPasswordRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 12.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import PMTestAutomation

fileprivate struct id {
    static let mailboxPasswordTextField = "MailboxPasswordViewController.passwordTextField"
    static let decryptButton = "MailboxPasswordViewController.decryptButton"
    static let decryptFailedStaticTextIdentifier = LocalString._the_mailbox_password_is_incorrect
}

class MailboxPasswordRobot: CoreElements {
    
    func decryptMailbox(_ mailboxPwd: String) -> InboxRobot {
        return mailboxPassword(mailboxPwd)
            .decrypt()
    }

    private func mailboxPassword(_ mailboxPwd: String) -> MailboxPasswordRobot {
        secureTextField(id.mailboxPasswordTextField).typeText(mailboxPwd)
        return self
    }
    
    private func decrypt() -> InboxRobot {
        button(id.decryptButton).tap()
        return InboxRobot()
    }
    
    func decryptMailboxWithInvalidPassword(_ mailboxPwd: String) -> ErrorDialogRobot {
        let incorrectPwd = "wrong" + mailboxPwd
        return mailboxPassword(incorrectPwd)
            .decryptWithWrongPassword()
    }
    
    private func decryptWithWrongPassword() -> ErrorDialogRobot {
        button(id.decryptButton).tap()
        return ErrorDialogRobot()
    }
    
    class ErrorDialogRobot {
        
        var verify = Verify()
        
        internal class Verify: CoreElements {
            
            func verifyDecryptFailedErrorDisplayed() {
                staticText(id.decryptFailedStaticTextIdentifier).wait().checkExists()
            }
            
        }
    }
}
