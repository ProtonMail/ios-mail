//
//  PasswordManagementRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion
import ProtonCoreQuarkCommands

fileprivate struct id {
    static let currentPasswordSecureTextFieldIdentifier = "Current password"
    static let newPasswordSecureTextFieldIdentifier = "New password"
    static let confirmNewPasswordSecureTextFieldIdentifier = "Confirm new password"
    static let saveNavBarButtonIdentifier = "Save"
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
