//
//  HumanVerificationTests.swift
//  ProtonMailUITests
//
//  Created by Greg on 16.04.21.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsHumanVerification
import ProtonCoreTestingToolkitUITestsLogin

class HumanVerificationTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var menuRobot = MenuRobot()

    override func setUp() {
        _launchArguments.append(contentsOf: ["HumanVerificationStubs", "1"])
        super.setUp()
        let user = users["plus"]!

        menuRobot = loginRobot
            .loginUser(user)
            .menuDrawer()
    }

    func testHumanVerification() {
        menuRobot
            .subscriptionAsHumanVerification()
            .verify.humanVerificationScreenIsShown()
            .emailTab()
            .smsTab()
            .captchaTab()
            .close(to: MenuRobot.self)
            .paymentsErrorDialog()      
    }
}
