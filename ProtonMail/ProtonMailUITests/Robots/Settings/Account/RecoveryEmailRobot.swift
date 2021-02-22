//
//  RecoveryEmailRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let saveNavBarButtonLabel = LocalString._general_save_action

/**
 * Class represents Email recovery view.
 */
class RecoveryEmailRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func changeRecoveryEmail(_ user: User) -> RecoveryEmailRobot {
        return newEmail(user.email)
            .save()
            .password(user.password)
            .confirmSave()
    }

    private func newEmail(_ email: String) -> RecoveryEmailRobot {
        Element.textField.tapByIndex(0).typeText(email)
        return self
    }

    private func password(_ password: String) -> RecoveryEmailRobot {
        Element.secureTextField.tapByIndex(0).typeText(password)
        return self
    }

    private func save() -> RecoveryEmailRobot {
        Element.button.tapByIdentifier(saveNavBarButtonLabel)
        return RecoveryEmailRobot()
    }

    private func confirmSave() -> RecoveryEmailRobot {

        return RecoveryEmailRobot()
    }

    /**
     * Contains all the validations that can be performed by [RecoveryEmailRobot].
     */
    class Verify {

        func recoveryEmailChangedTo(_ email: String) {

        }
    }
}
