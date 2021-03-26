//
//  SearchTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2021/1/13.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import XCTest

class SearchTests: BaseTestCase {
    
    var subject = String()
    var body = String()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }
    
    func testSearchFromInboxBySubject() {
        let user = testData.onePassUser
        let recipient = testData.onePassUser
        let replySubject = String(format: "Re: %@", subject)
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .searchBar()
            .searchMessageText(subject)
            .verify.messageExists(subject)
            .clickSearchedMessageBySubject(subject)
            .reply()
            .sendReplyMessage()
            .navigateBackToSearchResult()
            .goBackToInbox()
            .menuDrawer()
            .sent()
            .verify.messageExists(replySubject)
    }
    
    func testSearchFromInboxByAddress() {
        let user = testData.onePassUser
        let receiver = testData.externalEmailPGPEncrypted.email
        LoginRobot()
            .loginUser(user)
            .searchBar()
            .searchMessageText(receiver)
            .verify.addressExists(receiver, 0)
    }
    
    func testSearchDraft() {
        let user = testData.onePassUser
        let modifiedDraftTopic = String(format: "%@ modify subject test", subject)
        LoginRobot()
            .loginUser(user)
            .compose()
            .changeSubjectTo(subject)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .searchBar()
            .searchMessageText(subject)
            .verify.draftMessageExists(subject)
            .goBackToDrafts()
            .clickDraftBySubject(subject)
            .changeSubjectTo(modifiedDraftTopic)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .menuDrawer()
            .inbox()
            .searchBar()
            .searchMessageText(modifiedDraftTopic)
            .verify.draftMessageExists(modifiedDraftTopic)
    }
}
