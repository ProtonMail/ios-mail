//
//  LogoutTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class LogoutTests: FixtureAuthenticatedTestCase {

    func testLogoutOnePassUser() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .logoutUser()
                .verify.loginScreenIsShown()
        }
    }
}
