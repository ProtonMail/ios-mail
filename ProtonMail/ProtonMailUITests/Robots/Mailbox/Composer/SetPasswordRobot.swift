// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest
import pmtest

fileprivate struct id {
   
    /// Set Password screen identifiers.
    static let messagePasswordOtherIdentifier = "ComposePasswordVC.passwordText"
    static let messagePasswordSecureTextFieldIdentifier = "ComposePasswordVC.textField"
    
    static let confirmPasswordOtherIdentifier = "ComposePasswordVC.confirmText"
    static let confirmPasswordSecureTextFieldIdentifier = "ComposePasswordVC.textField"
    static let hintPasswordTextViewIdentifier = "ComposePasswordVC.passwordHintText"
    static let applyButtonIdentifier = "ComposePasswordVC.applyButton"
}

/**
 Class represents Message Password dialog.
 */
class SetPasswordRobot: CoreElements {
    func definePasswordWithHint(_ password: String, _ hint: String) -> ComposerRobot {
        return definePassword(password)
            .confirmPassword(password)
            .defineHint(hint)
            .applyPassword()
    }

    private func definePassword(_ password: String) -> SetPasswordRobot {
        otherElement(id.messagePasswordOtherIdentifier).onDescendant(secureTextField(id.messagePasswordSecureTextFieldIdentifier))
            .tap()
            .typeText(password)
        return self
    }

    private func confirmPassword(_ password: String) -> SetPasswordRobot {
        otherElement(id.confirmPasswordOtherIdentifier)
            .onDescendant(secureTextField(id.confirmPasswordSecureTextFieldIdentifier))
            .tap()
            .typeText(password)
        return self
    }

    private func defineHint(_ hint: String) -> SetPasswordRobot {
        textView(id.hintPasswordTextViewIdentifier).tap().typeText(hint)
        /// Workaround to dismiss keyboard.
        app.tap()
        return self
    }

    private func applyPassword() -> ComposerRobot {
        button(id.applyButtonIdentifier).tap()
        return ComposerRobot()
    }
}
