//
//  PasswordManagementRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let currentPasswordSecureTextFieldIdentifier = LocalString._settings_current_password
    static let newPasswordSecureTextFieldIdentifier = LocalString._settings_new_password
    static let confirmNewPasswordSecureTextFieldIdentifier = LocalString._settings_confirm_new_password
    static let saveNavBarButtonIdentifier = LocalString._general_save_action
}

/**
 Class represents Password management view.
 */
class SinglePasswordRobot: CoreElements {

    func changePassword(user: User) -> SettingsRobot {
        return currentPassword(user.password)
            .newPassword(user.password)
            .confirmNewPassword(user.password)
            .savePassword()
    }

    func currentPassword(_ password: String) -> SinglePasswordRobot {
        secureTextField().byIndex(0).tap().typeText(password)
        return self
    }

    func newPassword(_ password: String) -> SinglePasswordRobot {
        secureTextField().byIndex(1).tap().typeText(password)
        return self
    }

    func confirmNewPassword(_ password: String) -> SinglePasswordRobot {
        secureTextField().byIndex(2).tap().typeText(password)
        return self
    }

    func savePassword() -> SettingsRobot {
        button(id.saveNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }
}
