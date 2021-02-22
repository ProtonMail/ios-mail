//
//  PasswordManagementRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let currentPasswordSecureTextFieldIdentifier = LocalString._settings_current_password
private let newPasswordSecureTextFieldIdentifier = LocalString._settings_new_password
private let confirmNewPasswordSecureTextFieldIdentifier = LocalString._settings_confirm_new_password
private let saveNavBarButtonIdentifier = LocalString._general_save_action

/**
 Class represents Password management view.
 */
class SinglePasswordRobot {

    func changePassword(user: User) -> SettingsRobot {
        return currentPassword(user.password)
            .newPassword(user.password)
            .confirmNewPassword(user.password)
            .savePassword()
    }

    func currentPassword(_ password: String) -> SinglePasswordRobot {
        Element.secureTextField.tapByIndex(0).typeText(password)
        return self
    }

    func newPassword(_ password: String) -> SinglePasswordRobot {
        Element.secureTextField.tapByIndex(1).typeText(password)
        return self
    }

    func confirmNewPassword(_ password: String) -> SinglePasswordRobot {
        Element.secureTextField.tapByIndex(2).typeText(password)
        return self
    }

    func savePassword() -> SettingsRobot {
        Element.button.tapByIdentifier(saveNavBarButtonIdentifier)
        return SettingsRobot()
    }
}
