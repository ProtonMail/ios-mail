//
//  MailboxPasswordRobot.swift
//  ProtonCore-TestingToolkit - Created on 23.04.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import pmtest

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
