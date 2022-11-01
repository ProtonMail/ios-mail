//
//  SpamTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/4.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

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
            .menuDrawer()
            .inbox()
            .clickMessageBySubject(subject)
            .clickMoveToSpam()
            .menuDrawer()
            .spams()
            .verify.messageWithSubjectExists(subject)
    }
    
    
    //Spam is not the default swiping action
    func disabletestSwipeToSpamMessage() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .menuDrawer()
            .inbox()
            .spamMessageBySubject(subject)
            .menuDrawer()
            .spams()
            .verify.messageWithSubjectExists(subject)
    }
    
    //Clear spam messages is no longer available in v4
    func disabletestClearSpamMessages() {
        let user = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .spams()
            .clearSpamFolder()
            .verify.messageIsEmpty()
    }
}

