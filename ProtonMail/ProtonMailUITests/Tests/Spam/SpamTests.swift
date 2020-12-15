//
//  SpamTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

class SpamTests: BaseTestCase {
    var subject = String()
    var body = String()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }
    
    func testSpamMessageFromMessageDetail() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .clickMessageBySubject(subject)
            .clickMoveToSpam()
            .menuDrawer()
            .spams()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSwipeToSpamMessage() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .spamMessageBySubject(subject)
            .menuDrawer()
            .spams()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testClearSpamMessages() {
        let user = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .spams()
            .clearSpamFolder()
            .verify.messageIsEmpty()
    }
}

