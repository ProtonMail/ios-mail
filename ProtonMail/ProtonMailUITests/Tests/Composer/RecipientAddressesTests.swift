//
//  RecepientAddressesTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 02.02.21.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class RecipientAddressesTests: FixtureAuthenticatedTestCase {
    
    func testExistingRecepient() {
        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .compose()
                .recipients(user.dynamicDomainEmail)
                .verify.invalidAddressToastIsNotShown()
        }
    }
    
    func testNonExistingRecepient() {
        runTestWithScenario(.pgpmime) {
            let recipient = "not_\(user.dynamicDomainEmail)"

            InboxRobot()
                .compose()
                .recipients(recipient)
                .verify.recipientNotFoundToastIsShown()
        }
    }
    
    func xtestDeletedRecepient() {
        let user = testData.onePassUser
        let recipient = "liletestpayment@proton.me"
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.recipientNotFoundToastIsShown()
    }
    
    func xtestExistingNonPMRecepient() {
        let user = testData.onePassUser
        let recipient = testData.externalEmailPGPSigned.dynamicDomainEmail
        LoginRobot()
            .loginUser(user)
            .compose()
            .recipients(recipient)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func xtestContactGroupRecepient() {
        let user = testData.onePassUser
        let recipientGroup = "TestAutomation"
        LoginRobot()
            .loginUser(user)
            .compose()
            .typeAndSelectRecipients(recipientGroup)
            .verify.invalidAddressToastIsNotShown()
    }
    
    func testRecepientWithValidDomain() {
        let recipient = "mail@external.asd1230-123.asdinternal.asd.gm-ail.com"

        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .compose()
                .recipients(recipient)
                .verify.invalidAddressToastIsNotShown()
        }
    }
    
    func testRecepientWithInvalidDomain() {
        let recipient = "under_score@_*[>.ch"
        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .compose()
                .recipients(recipient)
                .verify.invalidAddressToastIsShown()
        }
    }
    
    func testRecepientWithInvalidEmailAddress() {
        let recipient = "Peléδοκιμή企.香二ノ宮.日медведь@с-балалайकडा.भा.рф"
        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .compose()
                .recipients(recipient)
                .verify.invalidAddressToastIsShown()
        }
    }
}
