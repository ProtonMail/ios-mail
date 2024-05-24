//
//  SpamTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest

class SpamTests: FixtureAuthenticatedTestCase {

    func testSpamSingleMessageFromLongClick() {
        runTestWithScenario(.trashOneMessage) {
            InboxRobot()
                .longClickMessageBySubject(scenario.subject)
                .moveTo()
                .selectFolder(LocalString._menu_spam_title)
            InboxRobot()
                .menuDrawer()
                .spam()
                .verify.messageExists(scenario.subject)
        }
    }

    func testSpamMessageFromDetailPage() {
        runTestWithScenario(.trashOneMessage) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .clickMoveToSpam()
                .menuDrawer()
                .spam()
                .verify.messageExists(scenario.subject)
        }
    }

    func testClearSpamMessages() {
        runTestWithScenario(.trashOneMessage) {
            InboxRobot()
                .longClickMessageBySubject(scenario.subject)
                .moveTo()
                .selectFolder(LocalString._menu_spam_title)
            InboxRobot()
                .menuDrawer()
                .spam()
                .clearSpamFolder()
                .verify.nothingToSeeHere()
        }
    }
}
