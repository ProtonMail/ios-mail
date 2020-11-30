//
//  ComposerTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//


class SendNewMessageTests: BaseTestCase {
    
    var subject = String()
    var body = String()
    
    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }
    
    func testSendMessageToInternalContact() {
        let user = testData.onePassUser
        let recipient = testData.internalEmailNotTrustedKeys
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSendMessageToInternalTrustedContact() {
        let to = testData.internalEmailTrustedKeys.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageToInternalNotTrustedContact() {
        let to = testData.internalEmailNotTrustedKeys.email
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
        let to = testData.externalEmailPGPEncrypted.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageToPGPSignedContact() {
        let to = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageEO() {
        let to = testData.externalEmailPGPSigned.email
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageWithPassword(to, subject, body, password, hint)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageExpiryTime() {
        let to = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageExpiryTimeInDays(to, subject, body, expireInDays: 2)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageEOAndExpiryTime() {
        let to = testData.externalEmailPGPSigned.email
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint
        LoginRobot()
            .loginTwoPasswordUser(testData.twoPassUser)
            .decryptMailbox(testData.twoPassUser.mailboxPassword)
            .compose()
            .sendMessageEOAndExpiryTime(to, subject, password, hint)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSendMessageToInternalNotTrustedContactChooseAttachment() {
        let to = testData.internalEmailNotTrustedKeys.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageWithAttachments(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageToInternalContactWithTwoAttachments() {
        let to = testData.internalEmailNotTrustedKeys.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageWithAttachments(to, subject, attachmentsAmount: 2)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSendMessageToExternalContactWithTwoAttachments() {
        let to = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageWithAttachments(to, subject, attachmentsAmount: 2)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }

    func testSendMessageToExternalContactWithOneAttachment() {
        let to = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .sendMessageWithAttachments(to, subject)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSendMessageEOAndExpiryTimeWithAttachment() {
        let to = testData.externalEmailPGPSigned.email
        let password = testData.editedPassword
        let hint = testData.editedPasswordHint
        LoginRobot()
            .loginTwoPasswordUser(testData.twoPassUser)
            .decryptMailbox(testData.twoPassUser.mailboxPassword)
            .compose()
            .sendMessageEOAndExpiryTimeWithAttachment(to, subject, password, hint)
            .menuDrawer()
            .sent()
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
    
    func testSendMessageFromPmMe() {
        let onePassUserPmMeAddress = testData.onePassUser.pmMeEmail
        let to = testData.internalEmailNotTrustedKeys.email
        LoginRobot()
            .loginUser(testData.onePassUser)
            .compose()
            .changeFromAddressTo(onePassUserPmMeAddress)
            .sendMessage(to, subject)
            .menuDrawer()
            .sent()
            .verify.messageExists(subject)
    }

    func testSendMessageWithAttachmentFromPmMe() {
        let onePassUserPmMeAddress = testData.onePassUser.pmMeEmail
        let to = testData.internalEmailNotTrustedKeys.email
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
//        let to = testData.internalEmailTrustedKeys.email
//        let cc = testData.externalEmailPGPSigned.email
//        LoginRobot()
//            .loginUser(testData.onePassUser)
//            .compose()
//            .sendMessage(to, cc, subject)
//            .menuDrawer()
//            .sent()
//            .verify.messageWithSubjectExists(subject)
//    }
//    func testSendMessageTOandCCandBCC() {
//        let to = testData.internalEmailTrustedKeys.email
//        let cc = testData.externalEmailPGPSigned.email
//        let bcc = testData.internalEmailNotTrustedKeys.email
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
