//
//  DraftsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

class DraftsTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var subject = String()
    private var body = String()
    private var to = String()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
        to = testData.twoPassUser.email
    }

    func testSaveDraft() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .verify.messageWithSubjectExists(subject)
    }

    func testSaveDraftWithAttachment() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBodyAttachment(to,subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .verify.messageWithSubjectExists(subject)
    }

    func testOpenDraftFromSearch() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftSubjectBody(subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .searchBar()
            .searchMessageText(subject)
            .clickSearchedDraftBySubject(subject)
            .verify.messageWithSubjectOpened(subject)
    }

    func testSendDraftWithAttachment() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBodyAttachment(to, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .send()
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(subject)
    }

    // 34849
    func testAddRecipientsToDraft() {
        let to = testData.internalEmailTrustedKeys.email
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftSubjectBody(subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .recipients(to)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .verify.messageWithSubjectAndRecipientExists(subject, to)
    }

    func testChangeDraftSender() {
        let onePassUserSecondEmail = "2\(testData.onePassUser.email)"

        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftSubjectBody(subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .changeFromAddressTo(onePassUserSecondEmail)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .clickDraftBySubject(subject)
            .verify.fromEmailIs(onePassUserSecondEmail)
    }
    
    func testChangeDraftSubjectAndSendMessage() {
        let newSubject = testData.messageSubject

        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .changeSubjectTo(newSubject)
            .send()
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(newSubject)
    }
    
    /// TestId: 34636
    func testSaveDraftWithoutSubject() {
        let noSubject = "(No_Subject)"
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToBody(to, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftByIndex(0)
            .send()
            .menuDrawer()
            .sent()
            .verify.messageExists(noSubject)
    }
    
    /// TestId: 34640
    func testMinimiseAppWhileComposingDraft() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject, body)
            .backgroundApp()
            .foregroundApp()
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .verify.messageWithSubjectExists(subject)
    }
    
    /// TestId: 35877
    func testEditDraftMinimiseAppAndSend() {
        let newRecipient = testData.onePassUserWith2Fa.email
        let newSubject = testData.newMessageSubject
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject, body)
            .backgroundApp()
            .foregroundApp()
            .editRecipients(newRecipient)
            .changeSubjectTo(newSubject)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(newSubject)
            .send()
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(newSubject)
    }
    
    /// TestId: 34634
    func testEditDraftMultipleTimesAndSend() {
        let editOneRecipient = testData.onePassUserWith2Fa.email
        let editTwoRecipient = testData.twoPassUserWith2Fa.email
        let editOneSubject = "Edit one \(Date().millisecondsSince1970)"
        let editTwoSubject = "Edit two \(Date().millisecondsSince1970)"
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .editRecipients(editOneRecipient)
            .changeSubjectTo(editOneSubject)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .clickDraftBySubject(editOneSubject)
            .editRecipients(editTwoRecipient)
            .changeSubjectTo(editTwoSubject)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .verify.messageWithSubjectExists(editTwoSubject)
    }
    
    /// TestId: 35856
    func testEditEveryFieldInDraftWithEnabledPublicKeyAndSend() {
        let newRecipient = testData.onePassUserWith2Fa.email
        let newSubject = testData.newMessageSubject
        loginRobot
            .loginTwoPasswordUser(testData.twoPassUser)
            .decryptMailbox(testData.twoPassUser.mailboxPassword)
            .compose()
            .draftToSubjectBody(testData.onePassUser.email, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .editRecipients(newRecipient)
            .changeSubjectTo(newSubject)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .clickDraftBySubject(newSubject)
            .send()
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(newSubject)
    }
    
    /// TestId: 35854
    func testEditDraftWithEnabledPublicKeyMultipleTimesAndSend() {
        let editOneRecipient = testData.onePassUserWith2Fa.email
        let editTwoRecipient = testData.onePassUser.email
        let editOneSubject = "Edit one \(Date().millisecondsSince1970)"
        let editTwoSubject = "Edit two \(Date().millisecondsSince1970)"
        loginRobot
            .loginTwoPasswordUser(testData.twoPassUser)
            .decryptMailbox(testData.twoPassUser.mailboxPassword)
            .compose()
            .draftToSubjectBody(testData.onePassUser.email, subject, body)
            .tapCancel()
            .confirmDraftSaving()
            .menuDrawer()
            .drafts()
            .clickDraftBySubject(subject)
            .editRecipients(editOneRecipient)
            .changeSubjectTo(editOneSubject)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .clickDraftBySubject(editOneSubject)
            .editRecipients(editTwoRecipient)
            .changeSubjectTo(editTwoSubject)
            .tapCancel()
            .confirmDraftSavingFromDrafts()
            .verify.messageWithSubjectExists(editTwoSubject)
    }
}
