//
//  LogoutTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LogoutTests: CleanAuthenticatedTestCase {
    
    private let loginRobot = LoginRobot()

    func testLogoutOnePassUser() {
        InboxRobot()
            .menuDrawer()
            .logoutUser()
            .verify.loginScreenIsShown()
    }
}
