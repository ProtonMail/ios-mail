//
//  RecepientAddressesTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.02.21.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

class RecepientAddressesTests: BaseTestCase {
    
    var subject = String()
    
    override func setUp() {
        super.setUp()
        subject = "Subject"
    }
    
    func testExistingRecepient() {
        let user = testData.onePassUser
        let recipient = testData.internalEmailTrustedKeys.email
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testNonExistingRecepient() {
        let user = testData.onePassUser
        let recipient = "not_existing_\(user.email)"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.recipientNotFoundToastIsShown()
    }
    
    func testDeletedRecepient() {
        let user = testData.onePassUser
        let recipient = "liletestpayment@protonmail.com"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.recipientNotFoundToastIsShown()
    }
    
    func testExistingNonPMRecepient() {
        let user = testData.onePassUser
        let recipient = testData.externalEmailPGPSigned.email
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testContactGroupRecepient() {
        let user = testData.onePassUser
        let recipientGroup = "TestAutomation"
        LoginRobot()
            .loginUser(user)
            .compose()
            .typeAndSelectRecipients(recipientGroup)
            .subject(subject)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testRecepientWithValidDomain() {
        let user = testData.onePassUser
        let recipient = "mail@external.asd1230-123.asdinternal.asd.gm-ail.com"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testRecepientWithInvalidDomain() {
        let user = testData.onePassUser
        let recipient = "i_like_underscore@but_*[>_not_allow_in_this_part.com"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.invalidAddressToastIsShown()
    }
    
    func testRecepientWithInvalidEmailAddress() {
        let user = testData.onePassUser
        let recipient = "Peléδοκιμή我買屋企.香港二ノ宮黒川.日本медведь@с-балалайкойसंपर्कडाटामेल.भारत.рф"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .subject(subject)
            .verify.invalidAddressToastIsShown()
    }
}
