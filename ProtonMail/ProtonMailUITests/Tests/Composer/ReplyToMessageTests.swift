//
//  ReplyToMessageTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import XCTest

class ReplyToMessageTests: BaseTestCase {
    
    let folder = "TestAutomationFolder"
    
    override func setUp() {
        super.setUp()
    }
    
    // ID: 31748
    func testReplyTextMessage() {
        let user = testData.onePassUser
        let subject = "Text message"
        let replySubject = String(format: "Re: %@ \(Date().millisecondsSince1970)", subject)
        
        LoginRobot()
            .loginUser(user)
            .menuDrawer()
            .folderOrLabel(folder)
            .clickMessageBySubject(subject)
            .reply()
            .changeSubjectTo(replySubject)
            .sendReplyMessage()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }
    
    // ID: 31750
    func testReplyMessageWithPublicKey() {
        let user = testData.twoPassUser
        let subject = "Text message"
        let replySubject = String(format: "Re: %@ \(Date().millisecondsSince1970)", subject)
        let folder = "ForwardReplyFolder"
        
        LoginRobot()
            .loginTwoPasswordUser(user)
            .decryptMailbox(user.mailboxPassword)
            .menuDrawer()
            .folderOrLabel(folder)
            .clickMessageBySubject(subject)
            .reply()
            .changeSubjectTo(replySubject)
            .sendReplyMessage()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }
    
    func testReplyAllMessage(){
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
            .sendReplyMessage()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }
    
    //ID: 31750
    func testReplyMessageWithAttachments() {
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
            .sendReplyMessage()
            .navigateBackToLabelOrFolder(folder)
            .menuDrawer()
            .inbox()
            .verify.messageExists(replySubject)
    }
}
