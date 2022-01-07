//
//  TrashTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

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
            .menuDrawer()
            .inbox()
            .longClickMessageBySubject(subject)
//            .addLabel()
//            .menuDrawer()
//            .trash()
//            .verify.messageWithSubjectExists(subject)
    }
    
    func testDeleteMessageFromDetailPage() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .menuDrawer()
            .inbox()
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
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject1)
            .compose()
            .sendMessage(recipient.email, subject2)
            .menuDrawer()
            .inbox()
            .longClickMessageBySubject(subject1)
//            .menuDrawer()
//            .trash()
//            .verify.messageSubjectsExist()
    }
    
    
    //Clear trash folder no longer available in v4
    func disabletestClearTrashFolder() {
        let user = testData.onePassUser
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .trash()
            .clearTrashFolder()
            .verify.messageIsEmpty()
    }
}
