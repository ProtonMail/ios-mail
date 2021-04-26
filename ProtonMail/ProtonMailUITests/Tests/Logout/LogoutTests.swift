//
//  LogoutTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LogoutTests: BaseTestCase {
    
    private let loginRobot = LoginRobot()

    func testLogoutOnePassUser() {
        let user = testData.onePassUser
        loginRobot
            .loginUser(user)
            .menuDrawer()
            .logoutUser()
            .verify.loginScreenIsShown()
    }
}
