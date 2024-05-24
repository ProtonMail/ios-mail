//
//  ForwardMessageTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation
import XCTest


class ForwardMessageTests: FixtureAuthenticatedTestCase {

    func testForwardTextMessage() {
        runTestWithScenario(.qaMail001) {
            let subject = "Fw: \(scenario.subject)"

            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .forward()
                .recipients(user.dynamicDomainEmail)
                .sendMessageFromMessageRobot()
                .navigateBackToInbox()
                .menuDrawer()
                .sent()
                .verify.messageExists(subject)
        }
    }
}
