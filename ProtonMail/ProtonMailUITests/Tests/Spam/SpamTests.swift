//
//  SpamTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

class SpamTests: NewFixtureAuthenticatedTestCase {

    override var scenario: MailScenario { .trashOneMessage }

    func testSpamSingleMessageFromLongClick() {
        InboxRobot()
            .longClickMessageBySubject(scenario.subject)
            .moveTo()
            .selectFolder(LocalString._menu_spam_title)
            .tapDone()
        InboxRobot()
            .menuDrawer()
            .spams()
            .verify.messageExists(scenario.subject)
    }

    func testSpamMessageFromDetailPage() {
        InboxRobot()
            .clickMessageBySubject(scenario.subject)
            .clickMoveToSpam()
            .menuDrawer()
            .spams()
            .verify.messageExists(scenario.subject)
    }

    func testClearSpamMessages() {
        InboxRobot()
            .longClickMessageBySubject(scenario.subject)
            .moveTo()
            .selectFolder(LocalString._menu_spam_title)
            .tapDone()
        InboxRobot()
            .menuDrawer()
            .spams()
            .clearSpamFolder()
            .verify.nothingToSeeHere()
    }
    
    func testSwipeRightToSpamMessage() {
        InboxRobot()
            .spamMessageBySubject(scenario.subject)
            .menuDrawer()
            .spams()
            .verify.messageExists(scenario.subject)
  }
}

