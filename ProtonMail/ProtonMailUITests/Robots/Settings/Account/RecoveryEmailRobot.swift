//
//  RecoveryEmailRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let saveNavBarButtonLabel = LocalString._general_save_action
}

/**
 * Class represents Email recovery view.
 */
class RecoveryEmailRobot: CoreElements {
    
    var verify = Verify()

    func changeRecoveryEmail(_ user: User) -> RecoveryEmailRobot {
        return newEmail(user.email)
            .save()
            .password(user.password)
            .confirmSave()
    }

    private func newEmail(_ email: String) -> RecoveryEmailRobot {
        textField().byIndex(0).tap().typeText(email)
        return self
    }

    private func password(_ password: String) -> RecoveryEmailRobot {
        secureTextField().byIndex(0).tap().typeText(password)
        return self
    }

    private func save() -> RecoveryEmailRobot {
        button(id.saveNavBarButtonLabel).tap()
        return RecoveryEmailRobot()
    }

    private func confirmSave() -> RecoveryEmailRobot {

        return RecoveryEmailRobot()
    }
    
    class Verify: CoreElements {
        
        func recoveryEmailChangedTo(_ email: String) {
            ///TODO: add implementation
        }
    }
}
