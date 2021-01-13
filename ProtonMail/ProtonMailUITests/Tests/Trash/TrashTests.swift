//
//  TrashTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

class TrashTests: BaseTestCase {
    
    var subject = String()
    var body = String()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }

    func testDeleteSingleMessageFromLongClick() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .deleteMessageWithLongClick(subject)
            .menuDrawer()
            .trash()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testDeleteMessageFromDetailPage() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .clickMessageBySubject(subject)
            .moveToTrash()
            .menuDrawer()
            .trash()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testDeleteMultipleMessages() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        let subject1 = "Test trash 1"
        let subject2 = "Test trash 2"
        let positions = [0,1]
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject1)
            .compose()
            .sendMessage(recipient.email, subject2)
            .refreshMailbox()
            .deleteMultipleMessages(positions)
            .menuDrawer()
            .trash()
            .verify.messageSubjectsExist()
    }
    
    func testClearTrashFolder() {
        let user = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .trash()
            .clearTrashFolder()
            .verify.messageIsEmpty()
    }
}
