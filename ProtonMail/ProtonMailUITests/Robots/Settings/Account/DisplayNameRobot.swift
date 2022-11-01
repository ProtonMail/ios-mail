//
//  DisplayNameRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let saveNavBarButtonLabel = LocalString._general_save_action
}

/**
 Class represents Display name view.
 */
class DisplayNameRobot: CoreElements {

    func setDisplayNameTextTo(_ text: String) -> DisplayNameRobot {
        textField().byIndex(0).tap().clearText().typeText(text)
        return self
    }
    
    func save() -> AccountSettingsRobot {
        button(id.saveNavBarButtonLabel).tap()
        return AccountSettingsRobot()
    }
}
