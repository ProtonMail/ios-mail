//
//  LogoutTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkit

class LogoutTests: FixtureAuthenticatedTestCase {
    
    private let loginRobot = LoginRobot()

    func testLogoutOnePassUser() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .logoutUser()
                .verify.loginScreenIsShown()
        }
    }
}
