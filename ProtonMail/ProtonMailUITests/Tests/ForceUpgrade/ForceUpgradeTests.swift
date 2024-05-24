//
//  ForceUpgradeTests.swift
//  ProtonMailUITests
//
//  Created by Greg on 17.04.21.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class ForceUpgradeTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var menuRobot = MenuRobot()

    override func setUp() {
        _launchArguments.append(contentsOf: ["ForceUpgradeStubs", "1"])
        super.setUp()
        let freeUser = users["plus"]!

        menuRobot = loginRobot
            .loginUser(freeUser)
            .menuDrawer()
    }

    func testForceUpgrade() {
        menuRobot
            .subscriptionAsForceUpgrade()
            .forceUpgradeDialog()
            .verify.checkDialog()
            .learnMoreButtonTap()
            .back()
            .upgradeButtonTap()
            .back()
            .verify.checkDialog()
    }
}
