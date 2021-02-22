//
//  DisplayNameRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let saveNavBarButtonLabel = LocalString._general_save_action

/**
 Class represents Display name view.
 */
class DisplayNameRobot {

    func setDisplayNameTextTo(_ text: String) -> DisplayNameRobot {
        Element.textField.tapByIndex(0).clear().typeText(text)
        return self
    }
    
    func save() -> AccountSettingsRobot {
        Element.button.tapByIdentifier(saveNavBarButtonLabel)
        return AccountSettingsRobot()
    }
}
