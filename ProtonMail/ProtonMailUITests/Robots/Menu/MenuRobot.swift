//
//  MenuRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

private let logoutStaticText = "MenuTableViewCell.\(LocalizedString()._sign_out)"
private let logoutConfirmButton = "MenuTableViewCell.\(LocalString._menu_signout_title)"
private let sentStaticText = "MenuTableViewCell.\(LocalString._menu_sent_title)"
private let sidebarHeaderViewOtherIdentifier = "MenuViewController.headerView"
private let manageAccountsStaticTextIdentifier = "MenuButtonViewCell.\(LocalString._menu_manage_accounts.replaceSpaces())"

/**
 Represents Menu view.
*/
class MenuRobot {
    
    func logoutUser() -> LoginRobot {
        return logout()
            .confirmLogout()
    }
    
    func sent() -> SentRobot {
        Element.wait.forSecureTextFieldWithIdentifier(sentStaticText, file: #file, line: #line).tap()
        return SentRobot()
    }
    
    func accountsList() -> MenuAccountListRobot {
        Element.wait.forOtherFieldWithIdentifier(sidebarHeaderViewOtherIdentifier, file: #file, line: #line).tap()
        return MenuAccountListRobot()
    }
    
    private func logout() -> MenuRobot {
        Element.staticText.tapByIdentifier(logoutStaticText)
        return self
    }
    
    private func confirmLogout() -> LoginRobot {
        Element.button.tapByIdentifier(logoutConfirmButton)
        return LoginRobot()
    }
    
    /**
     MenuAccountListRobot class contains actions and verifications for Account list functionality inside Menu drawer
     */
    class MenuAccountListRobot {
        
        var verify: Verify! = nil
        
        init() {
            verify = Verify()
        }

        func manageAccounts() -> AccountManagerRobot {
            Element.wait.forCellWithIdentifier(manageAccountsStaticTextIdentifier, file: #file, line: #line).tap()
            return AccountManagerRobot()
        }

        func switchToAccount(_ user: User) -> InboxRobot {
            Element.wait.forCellWithIdentifier("\(user.email)_MenuUserCell", file: #file, line: #line).tap()
            return InboxRobot()
        }

        /**
         Contains all the validations that can be performed by [MenuAccountListRobot].
         */
        class Verify {

            func accountAdded(_ user: User) {
                Element.wait.forStaticTextFieldWithIdentifier(user.email, file: #file, line: #line)
                Element.wait.forStaticTextFieldWithIdentifier(user.name, file: #file, line: #line)
            }
        }
    }
}
