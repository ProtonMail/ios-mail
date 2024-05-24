//
//  ReplyToMessageTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation
import XCTest

import ProtonCoreTestingToolkitUITestsLogin

class ReplyToMessageTests: FixtureAuthenticatedTestCase {

    let folder = "TestAutomationFolder"
    
    func testReplyTextMessage() {
        runTestWithScenario(.qaMail002) {

            let subject = "Re: \(scenario.subject)"

            InboxRobot()
                .clickMessageByIndex(0)
                .verify.messageBodyWithStaticTextExists("Auto generated email")
                .reply()
                .changeSubjectTo(subject)
                .sendMessageFromMessageRobot()
                .navigateBackToInbox()
                .menuDrawer()
                .sent()
                .verify.messageExists(subject)
        }
    }

    // TODO: backend need a message with public key 
    // ID: 31750
    func xtestReplyMessageWithPublicKey() {
        let user = testData.twoPassUser
        let subject = "Text message"
        let replySubject = String(format: "Re: %@ \(Date().millisecondsSince1970)", subject)
        let folder = "ForwardReplyFolder"
        
        LoginRobot()
            .loginTwoPasswordUser(user)
            .menuDrawer()
            .folderOrLabel(folder)
            .clickMessageBySubject(subject)
            .reply()
            .changeSubjectTo(replySubject)
            .sendMessageFromMessageRobot()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }

    // TODO: backend need a message with multiple from field
    func xtestReplyAllMessage(){
        let user = testData.onePassUser
        let subject = "Text message"
        let replySubject = String(format: "Re: %@ \(Date().millisecondsSince1970)", subject)
        
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .folderOrLabel(folder)
            .clickMessageBySubject(subject)
            .replyAll()
            .changeSubjectTo(replySubject)
            .sendMessageFromMessageRobot()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }

    // TODO: backend need a message with an attachment
    //ID: 31750
    func xtestReplyMessageWithAttachments() {
        let user = testData.onePassUser
        let subject = "Message with attachments"
        let replySubject = String(format: "Re: %@ \(Date().millisecondsSince1970)", subject)
        
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .folderOrLabel(folder)
            .clickMessageBySubject(subject)
            .reply()
            .changeSubjectTo(replySubject)
            .sendMessageFromMessageRobot()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }
}
