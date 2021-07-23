//
//  TwoFaRobot.swift
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

private let twoFAFieldId = "TwoFactorViewController.codeTextField.textField"
private let authenticateButtonId = "TwoFactorViewController.authenticateButton"
private let recoveryCodeButtonId = "TwoFactorViewController.recoveryCodeButton"
private let twoFALabel = "Two-factor authentication"
private let twoFATitleLabel = "TwoFactorViewController.codeTextField.titleLabel"
private let invalidCredentialStaticText = "Incorrect login credentials. Please try again"

public final class TwoFaRobot: CoreElements {
    
    public func fillTwoFACode(code: String) -> TwoFaRobot {
        textField(twoFAFieldId).tap().typeText(code)
        return self
    }
    
    public func confirm2FA<T: CoreElements>(robot _: T.Type) -> T {
        button(authenticateButtonId).tap().wait(time: 20)
        return T()
    }
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        
        public func incorrectCredentialsErrorDialog() {
            textView(invalidCredentialStaticText).wait().checkExists()
        }
    }
}
