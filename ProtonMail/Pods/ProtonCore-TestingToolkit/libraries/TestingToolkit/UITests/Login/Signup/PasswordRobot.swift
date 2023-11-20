//
//  PasswordRobot.swift
//  ProtonCore-TestingToolkit - Created on 21.04.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if canImport(fusion)

import Foundation
import fusion
import ProtonCoreLoginUI

private let titleId = "PasswordViewController.createPasswordTitleLabel"
private let passwordNameTextFieldId = "PasswordViewController.passwordTextField.textField"
private let repeatPasswordNameTextFieldId = "PasswordViewController.repeatPasswordTextField.textField"
private let nextButtonId = "PasswordViewController.nextButton"
private let errorBannerPassEmpty = LUITranslation.error_password_empty.l10n
private let errorBannerPassTooShort = String(format: LUITranslation.error_password_too_short.l10n, NSNumber(8))
private let errorBannerPassNotEqual = LUITranslation.error_password_not_equal.l10n
private let errorBannerButton = LUITranslation._core_ok_button.l10n
private let backtButtonName = "Back"

public final class PasswordRobot: CoreElements {

    public let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func passwordScreenIsShown() -> PasswordRobot {
            staticText(titleId).waitUntilExists().checkExists()
            return PasswordRobot()
        }

        @discardableResult
        public func passwordEmpty() -> PasswordRobot {
            textView(errorBannerPassEmpty).waitUntilExists().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }

        @discardableResult
        public func passwordTooShort() -> PasswordRobot {
            textView(errorBannerPassTooShort).waitUntilExists().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }

        @discardableResult
        public func passwordNotEqual() -> PasswordRobot {
            textView(errorBannerPassNotEqual).waitUntilExists().checkExists()
            button(errorBannerButton).tap()
            return PasswordRobot()
        }
    }

    public func insertPassword(password: String) -> PasswordRobot {
        secureTextField(passwordNameTextFieldId).waitUntilExists().tap().typeText(password)
        return self
    }

    public func clearPassword() -> PasswordRobot {
        _ = secureTextField(passwordNameTextFieldId).tap().clearText()
        return self
    }

    public func insertRepeatPassword(password: String) -> PasswordRobot {
        secureTextField(repeatPasswordNameTextFieldId).tap().typeText(password)
        return self
    }

    public func nextButtonTap<T: CoreElements>(robot _: T.Type) -> T {
        button(nextButtonId).tap()
        return T()
    }
}

#endif
