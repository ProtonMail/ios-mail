//
//  ForceUpgradeTests.swift
//  ProtonMailUITests
//
//  Created by Greg on 17.04.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

class ForceUpgradeTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var menuRobot = MenuRobot()

    override func setUp() {
        forceUpgradeStubs = true
        super.setUp()

        menuRobot = loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
    }

    func testForceUpgrade() {
        menuRobot
            .subscriptionAsForceUpgrade()
            .forceUpgradeDialog()
            .verify.checkDialog()
            .learnMoreButtonTap()
            .wait(timeInterval: 2.0)
            .back()
            .upgradeButtonTap()
            .wait(timeInterval: 2.0)
            .back()
            .verify.checkDialog()
    }
}
