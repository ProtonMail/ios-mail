//
//  SettingsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 26.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate func accountCellIdentifier(_ name: String) -> String { return "SettingsTwoLinesCell.\(name)" }
fileprivate let menuNavBarButtonIdentifier = "UINavigationItem.revealToggle"
fileprivate let menuButton = LocalString._menu_button
fileprivate let pinStaticTextIdentifier = LocalString._pin
/**
 * [SettingsRobot] class contains actions and verifications for Settings view.
 */
class SettingsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func menuDrawer() -> MenuRobot {
        Element.wait.forHittableButton(menuButton).tap()
        return MenuRobot()
    }
    @discardableResult
    func selectAccount(_ email: String) -> AccountSettingsRobot {
        Element.wait.forCellWithIdentifier(accountCellIdentifier(email)).tap()
        return AccountSettingsRobot()
    }
    
    func pin() -> PinRobot {
        Element.wait.forStaticTextFieldWithIdentifier(pinStaticTextIdentifier, file: #file, line: #line).tap()
        return PinRobot()
    }
    /**
     * Contains all the validations that can be performed by [SettingsRobot].
     */
    class Verify {

        func settingsOpened() {
            //TODO: implementation verification
        }
    }
}
