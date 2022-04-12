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
    static let menuNavBarButtonIdentifier = "UINavigationItem.revealToggle"
    static let menuButton = LocalString._menu_button
    static let pinCellIdentifier = "SettingsGeneralCell.App_PIN"
    static let swipeActionStaticTextIdentifier = LocalString._swipe_actions
    static let clearLocalCacheStaticTextIdentifier = LocalString._clear_local_message_cache
}

/**
 * [SettingsRobot] class contains actions and verifications for Settings view.
 */
class SettingsRobot: CoreElements {
    
    var verify = Verify()

    func menuDrawer() -> MenuRobot {
        button(id.menuButton).tap()
        return MenuRobot()
    }
    
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
    /**
     * Contains all the validations that can be performed by [SettingsRobot].
     */
    class Verify {

        func settingsOpened() {
            //TODO: implementation verification
        }
    }
}
