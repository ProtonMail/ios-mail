//
//  DraftsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit


class DraftsTests: FixtureAuthenticatedTestCase {
    
    private var subject = String()
    private var body = String()
    private var to = String()
    private var composerRobot: ComposerRobot = ComposerRobot()

    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
        to = users["pro"]!.email
    }

    func testSaveDraft() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSaveDraftWithAttachment() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBodyAttachment(to,subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .verify.messageWithSubjectExists(subject)
        }
    }

    /// TestId: 35854
    func testEditDraftMultipleTimes() throws {
        runTestWithScenario(.qaMail001) {
            let plusUser = users["plus"]!
            let freeUser = users["free"]!
            
            let editOneRecipient = plusUser.email
            let editOneSubject = "Edit one \(Date().millisecondsSince1970)"
            
            let editTwoRecipient = freeUser.email
            let editTwoSubject = "Edit two \(Date().millisecondsSince1970)"
            
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .editRecipients(editOneRecipient)
                .changeSubjectTo(editOneSubject)
                .tapCancelFromDrafts()
                .clickDraftBySubject(editOneSubject)
                .editRecipients(editTwoRecipient)
                .changeSubjectTo(editTwoSubject)
                .tapCancelFromDrafts()
                .verify.messageWithSubjectExists(editTwoSubject)
        }
    }

    func testOpenDraftFromSearch() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftSubjectBody(subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .searchBar()
                .searchMessageText(subject)
                .clickSearchedDraftBySubject(subject)
                .verify.messageWithSubjectOpened(subject)
        }
    }

    func testSendDraftWithAttachment() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBodyAttachment(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .send()
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // 34849
    func testAddRecipientsToDraft() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftSubjectBody(subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .typeAndSelectRecipients(to)
                .tapCancelFromDrafts()
                .verify.messageWithSubjectAndRecipientExists(subject, to)
        }
    }

    // Need an account with aliases to enable test back
    func disabledChangeDraftSender() {
        let onePassUserSecondEmail = "2\(testData.onePassUser.email)"

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftSubjectBody(subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .changeFromAddressTo(onePassUserSecondEmail)
                .tapCancelFromDrafts()
                .clickDraftBySubject(subject)
                .verify.fromEmailIs(onePassUserSecondEmail)
        }
    }

    func testChangeDraftSubjectAndSendMessage() {
        let newSubject = testData.messageSubject

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .changeSubjectTo(newSubject)
                .send()
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(newSubject)
        }
    }

    /// TestId: 34636
    func testSaveDraftWithoutSubject() {
        let noSubject = "(No Subject)"
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToBody(to, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftByIndex(0)
                .send()
                .menuDrawer()
                .sent()
                .verify.messageExists(noSubject)
        }
    }

    /// TestId: 34640
    func testMinimiseAppWhileComposingDraft() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .backgroundApp()
                .foregroundApp()
                .tapCancel()
                .menuDrawer()
                .drafts()
                .verify.messageWithSubjectExists(subject)
        }
    }

    /// TestId: 35877
    func testEditDraftMinimiseAppAndSend() {
        let newRecipient = users["plus"]!.email
        let newSubject = testData.newMessageSubject
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .backgroundApp()
                .foregroundApp()
                .editRecipients(newRecipient)
                .changeSubjectTo(newSubject)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(newSubject)
                .send()
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(newSubject)
        }
    }

    /// TestId: 34634
    func testEditDraftMultipleTimesAndSend() {
        let plusUser = users["plus"]!
        let proUser = users["pro"]!
        let editOneSubject = "Edit one \(Date().millisecondsSince1970)"
        let editTwoSubject = "Edit two \(Date().millisecondsSince1970)"
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .editRecipients(plusUser.email)
                .changeSubjectTo(editOneSubject)
                .tapCancelFromDrafts()
                .clickDraftBySubject(editOneSubject)
                .editRecipients(proUser.email)
                .changeSubjectTo(editTwoSubject)
                .tapCancelFromDrafts()
                .verify.messageWithSubjectExists(editTwoSubject)
        }
    }

    /// TestId: 35856
    func testEditEveryFieldInDraftWithEnabledPublicKeyAndSend() {
        let newRecipient = users["plus"]!.email
        let newSubject = testData.newMessageSubject
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .editRecipients(newRecipient)
                .changeSubjectTo(newSubject)
                .tapCancelFromDrafts()
                .clickDraftBySubject(newSubject)
                .send()
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(newSubject)
        }
    }

    /// TestId: 35854
    func testEditDraftWithEnabledPublicKeyMultipleTimesAndSend() {
        let editOneRecipient = users["free"]!.email
        let editTwoRecipient = users["plus"]!.email
        let editOneSubject = "Edit one \(Date().millisecondsSince1970)"
        let editTwoSubject = "Edit two \(Date().millisecondsSince1970)"
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .draftToSubjectBody(to, subject, body)
                .tapCancel()
                .menuDrawer()
                .drafts()
                .clickDraftBySubject(subject)
                .editRecipients(editOneRecipient)
                .changeSubjectTo(editOneSubject)
                .tapCancelFromDrafts()
                .clickDraftBySubject(editOneSubject)
                .editRecipients(editTwoRecipient)
                .changeSubjectTo(editTwoSubject)
                .tapCancelFromDrafts()
                .verify.messageWithSubjectExists(editTwoSubject)
        }
    }
}
