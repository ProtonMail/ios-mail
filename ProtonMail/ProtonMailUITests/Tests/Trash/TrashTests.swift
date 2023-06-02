//
//  TrashTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

class TrashOneTests: NewFixtureAuthenticatedTestCase {

    override var scenario: MailScenario { .trashOneMessage }

    func testDeleteSingleMessageFromLongClick() {
        InboxRobot()
            .longClickMessageBySubject(scenario.subject)
            .moveToTrash()
            .menuDrawer()
            .trash()
            .verify.messageExists(scenario.subject)
    }
    
    func testDeleteMessageFromDetailPage() {
        InboxRobot()
            .clickMessageBySubject(scenario.subject)
            .moveToTrash()
            .menuDrawer()
            .trash()
            .verify.messageExists(scenario.subject)
    }
}

class TrashMultipleTests: NewFixtureAuthenticatedTestCase {

    override var scenario: MailScenario { .trashMultipleMessages }

    func testDeleteMultipleMessages() {
        InboxRobot()
            .selectMultipleMessages([0,2])
            .moveToTrash()
            .menuDrawer()
            .trash()
            .verify.numberOfMessageExists(2)
    }

    func testClearTrashFolder() {
        InboxRobot()
            .selectMultipleMessages([0,1])
            .moveToTrash()
            .menuDrawer()
            .trash()
            .clearTrashFolder()
            .verify.nothingToSeeHere()
    }
}
