//
//  DraftsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class DraftsTests: BaseTestCase {

    private let loginRobot = LoginRobot()
    private var subject = String()
    private var body = String()
    private var to = String()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
        to = testData.internalEmailTrustedKeys.email
    }

    func testSaveDraft() {
        loginRobot
            .loginUser(testData.onePassUser)
            .compose()
            .draftToSubjectBody(to, subject)
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
            .draftSubjectBody(subject, body)
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
}
