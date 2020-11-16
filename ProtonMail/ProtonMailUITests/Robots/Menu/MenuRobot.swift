//
//  MenuRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

private let logoutStaticText = "Logout"
private let logoutConfirmButton = "Log out"
private let sentStaticText = "Sent"

/**
 Represents Menu view.
*/
class MenuRobot {
    
    func logoutUser() -> LoginRobot {
        return logout()
            .confirmLogout()
    }
    
    func sent() -> SentRobot {
        Element.staticText.tapByIdentifier(sentStaticText)
        return SentRobot()
    }
    
    private func logout() -> MenuRobot {
        Element.staticText.tapByIdentifier(logoutStaticText)
        return self
    }
    
    private func confirmLogout() -> LoginRobot {
        Element.button.tapByIdentifier(logoutConfirmButton)
        return LoginRobot()
    }
}
