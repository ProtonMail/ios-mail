//
//  TwoFaRobot.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-04-23.
//

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

