//
//  SettingsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 26.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static func accountCellIdentifier(_ name: String) -> String { return "SettingsTwoLinesCell.\(name)" }
    static let closeButtonIdentifier = LocalString._general_close_action
    static let menuNavBarButtonIdentifier = "UINavigationItem.revealToggle"
    static let menuButtonIdentifier = "MailboxViewController.menuBarButtonItem"
    static let pinCellIdentifier = "SettingsGeneralCell.App_PIN"
    static let swipeActionStaticTextIdentifier = LocalString._swipe_actions
    static let clearLocalCacheStaticTextIdentifier = LocalString._empty_cache
    static let darkModeCellIdentifier = "SettingsGeneralCell.Dark_mode"
    static let darkModeToggleStateStaticTextIdentifier = "Dark_mode.rightText"
}

/**
 * [SettingsRobot] class contains actions and verifications for Settings view.
 */
class SettingsRobot: CoreElements {
    
    var verify = Verify()
    
    @discardableResult
    func selectAccount(_ email: String) -> AccountSettingsRobot {
        staticText(email).tap()
        return AccountSettingsRobot()
    }
    
    func clearCache() -> SettingsRobot {
        staticText(id.clearLocalCacheStaticTextIdentifier).tap()
        return SettingsRobot()
    }
    
    func pin() -> PinRobot {
        cell(id.pinCellIdentifier).tap()
        return PinRobot()
    }

    func close() -> InboxRobot {
        button(id.closeButtonIdentifier).tap()
        return InboxRobot()
    }

    func selectDarkMode() -> DarkModeRobot {
        cell(id.darkModeCellIdentifier).tap()
        return DarkModeRobot()
    }

    /**
     * Contains all the validations that can be performed by [SettingsRobot].
     */
    class Verify: CoreElements {

        func settingsOpened() {
            //TODO: implementation verification
        }
        
        func darkModeIsOn() {
            staticText(id.darkModeToggleStateStaticTextIdentifier).checkHasLabel("On")
        }
        
        func darkModeIsOff() {
            staticText(id.darkModeToggleStateStaticTextIdentifier).checkHasLabel("Off")
        }
    }
}
