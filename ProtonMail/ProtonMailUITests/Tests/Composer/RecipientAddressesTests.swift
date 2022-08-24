//
//  RecepientAddressesTests.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 02.02.21.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class RecipientAddressesTests: BaseTestCase {
    
    func testExistingRecepient() {
        let user = testData.onePassUser
        let recipient = testData.internalEmailTrustedKeys.email
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testNonExistingRecepient() {
        let user = testData.onePassUser
        let recipient = "not_\(user.pmMeEmail)"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.recipientNotFoundToastIsShown()
    }
    
    func testDeletedRecepient() {
        let user = testData.onePassUser
        let recipient = "liletestpayment@protonmail.com"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.recipientNotFoundToastIsShown()
    }
    
    func testExistingNonPMRecepient() {
        let user = testData.onePassUser
        let recipient = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testContactGroupRecepient() {
        let user = testData.onePassUser
        let recipientGroup = "TestAutomation"
        LoginRobot()
            .loginUser(user)
            .compose()
            .typeAndSelectRecipients(recipientGroup)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testRecepientWithValidDomain() {
        let user = testData.onePassUser
        let recipient = "mail@external.asd1230-123.asdinternal.asd.gm-ail.com"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testRecepientWithInvalidDomain() {
        let user = testData.onePassUser
        let recipient = "under_score@_*[>.ch"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsShown()
    }
    
    func testRecepientWithInvalidEmailAddress() {
        let user = testData.onePassUser
        let recipient = "Peléδοκιμή企.香二ノ宮.日медведь@с-балалайकडा.भा.рф"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsShown()
    }
}
