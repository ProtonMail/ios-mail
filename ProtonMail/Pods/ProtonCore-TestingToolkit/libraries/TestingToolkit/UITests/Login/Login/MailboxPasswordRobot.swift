//
//  MailboxPasswordRobot.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-04-23.
//

import PMTestAutomation

private let labelUnlockYourMailboxText = "Unlock your mailbox"
private let mailboxPasswordTextFieldId = "MailboxPasswordViewController.mailboxPasswordTextField.textField"
private let unlockButtonId = "MailboxPasswordViewController.unlockButton"
private let forgotPassword = "MailboxPasswordViewController.forgetButton"
private let incorrectMailboxPasswordStaticText = "Incorrect mailbox password"


public final class MailboxPasswordRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        
        public func labelUnlockYourMailbox() {
            staticText(labelUnlockYourMailboxText).checkExists()
        }
        
        public func incorrectMailboxPasswordErrorDialog() {
            textView(incorrectMailboxPasswordStaticText).wait().checkExists()
        }
    }
    
    public func fillMailboxPassword(mailboxPassword: String) -> MailboxPasswordRobot {
        secureTextField(mailboxPasswordTextFieldId).wait().tap().typeText(mailboxPassword)
        return self
    }
    
    public func unlock<T: CoreElements>(robot _: T.Type) -> T {
        button(unlockButtonId).tap().wait()
        return T()
    }
}
