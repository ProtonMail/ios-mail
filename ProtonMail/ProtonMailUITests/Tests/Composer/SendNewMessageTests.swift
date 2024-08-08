//
//  ComposerTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class SendNewMessageTests: FixtureAuthenticatedTestCase {
    
    var subject = String()
    var body = String()
    
    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }
    
    func testSendMessageToInternalContact() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessage(user.pmMeEmail, subject)
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(subject)
        }
    }
    
    func testSendMessageToInternalTrustedContact() {
        runTestWithScenario(.pgpinlineDrafts) {
            InboxRobot()
                .compose()
                .sendMessage(user.pmMeEmail, subject)
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // TODO: backend need a not trusted contact
    func xtestSendMessageToInternalNotTrustedContact() {
        let to = testData.internalEmailNotTrustedKeys.dynamicDomainEmail
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageToPGPEncryptedContact() {
        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .compose()
                .sendMessage(user.pmMeEmail, subject)
                .menuDrawer()
                .sent()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func xtestSendMessageToPGPSignedContact() {
        runTestWithScenario(.pgpinlineDrafts) {
            let contact = Contact.getContact(byName: "Signed+PGPInline Trusted Proton Contact", contacts: scenario.contacts)

            InboxRobot()
                .compose()
                .sendMessage(contact!.name, subject)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSendMessageEO() {
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessageWithPassword(user.dynamicDomainEmail, subject, body, password, hint)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSendMessageExpiryTime() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessageExpiryTimeInDays(user.dynamicDomainEmail, subject, body, expirePeriod: .oneDay)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSendMessageEOAndExpiryTime() {
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessageEOAndExpiryTime(user.dynamicDomainEmail, subject, password, hint, expirePeriod: .oneDay)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // TODO: update .pgpinline when it works
    func testSendMessageToInternalNotTrustedContactChooseAttachment() {
        runTestWithScenario(.pgpinlineDrafts) {
            let contact = Contact.getContact(byName: "Not Signed External Contact", contacts: scenario.contacts)

            InboxRobot()
                .compose()
                .sendMessageWithAttachments(contact!.name, subject)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSendMessageToInternalContactWithTwoAttachments() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessageWithAttachments(user.dynamicDomainEmail, subject, attachmentsAmount: 2)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // TODO: update .pgpinline when it works
    func testSendMessageToExternalContactWithTwoAttachments() {
        runTestWithScenario(.pgpinlineDrafts) {
            let contact = Contact.getContact(byName: "Not Signed External Contact", contacts: scenario.contacts)

            InboxRobot()
                .compose()
                .sendMessageWithAttachments(contact!.name, subject, attachmentsAmount: 2)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // TODO: update .pgpinline when it works
    func testSendMessageToExternalContactWithOneAttachment() {
        runTestWithScenario(.pgpinlineDrafts) {
            let contact = Contact.getContact(byName: "Signed External Contact", contacts: scenario.contacts)

            InboxRobot()
                .compose()
                .sendMessageWithAttachments(contact!.name, subject)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    func testSendMessageEOAndExpiryTimeWithAttachment() {
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .compose()
                .sendMessageEOAndExpiryTimeWithAttachment(user.dynamicDomainEmail, subject, password, hint, expirePeriod: .oneDay)
                .menuDrawer()
                .sent()
                .refreshMailbox()
                .verify.messageWithSubjectExists(subject)
        }
    }

    // TODO: backend need a user with another pm me address
    func xtestSendMessageFromPmMe() {
        runTestWithScenario(.pgpinline) {
            InboxRobot()
                .compose()
                .changeFromAddressTo(user.pmMeEmail)
                .sendMessage(user.dynamicDomainEmail, subject)
                .menuDrawer()
                .sent()
                .verify.messageExists(subject)
        }
    }

    // TODO: backend need a user with another pm me address
    func xtestSendMessageWithAttachmentFromPmMe() {
        let onePassUserPmMeAddress = testData.onePassUser.pmMeEmail
        let to = testData.internalEmailNotTrustedKeys.dynamicDomainEmail
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .changeFromAddressTo(onePassUserPmMeAddress)
            .sendMessageWithAttachments(to, subject)
            .menuDrawer()
            .sent()
            .verify.messageExists(subject)
    }
    
    /// Disabled due to issue with CC and BCC fields location
    //    func testSendMessageTOandCC() {
    //        let to = testData.internalEmailTrustedKeys.dynamicDomainEmail
    //        let cc = testData.externalEmailPGPSigned.dynamicDomainEmail
    //        LoginRobot()
    //            .loginUser(testData.onePassUser)
    //            .compose()
    //            .sendMessage(to, cc, subject)
    //            .menuDrawer()
    //            .sent()
    //            .verify.messageWithSubjectExists(subject)
    //    }
    //    func testSendMessageTOandCCandBCC() {
    //        let to = testData.internalEmailTrustedKeys.dynamicDomainEmail
    //        let cc = testData.externalEmailPGPSigned.dynamicDomainEmail
    //        let bcc = testData.internalEmailNotTrustedKeys.dynamicDomainEmail
    //        LoginRobot()
    //            .loginUser(testData.onePassUser)
    //            .compose()
    //            .sendMessage(to, cc, bcc, subject)
    //            .menuDrawer()
    //            .sent()
    //            .verify.messageWithSubjectExists(subject)
    //    }
    //
}
