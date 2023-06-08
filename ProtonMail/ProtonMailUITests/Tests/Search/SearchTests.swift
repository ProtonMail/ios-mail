//
//  SearchTests.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2021/1/13.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import XCTest

import ProtonCore_TestingToolkit

class SearchTests: FixtureAuthenticatedTestCase {
    
    var subject = String()
    var body = String()
    
    override func setUp() {
        super.setUp()
        subject = testData.messageSubject
        body = testData.messageBody
    }
    
    func xtestSearchFromInboxBySubject() {
        let user = testData.onePassUser
        let recipient = testData.twoPassUser
        LoginRobot()
            .loginUser(user)
            .compose()
            .sendMessage(recipient.email, subject)
            .refreshMailbox()
            .searchBar()
            .searchMessageText(subject)
            .verify.messageExists(subject)
    }
    
    func xtestSearchFromInboxByAddress() {
        let user = testData.onePassUser
        let coreFusionSender = "Core Fusion"
        let title = "163880735864890"
        LoginRobot()
            .loginUser(user)
            .searchBar()
            .searchMessageText(coreFusionSender)
            .verify.senderAddressExists(coreFusionSender, title)
    }
    
    func xtestSearchDraft() {
        runTestWithScenario(.pgpinlineDrafts) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject) //workoarund for atlas env search
                .navigateBackToInbox()
                .searchBar()
                .searchMessageText(scenario.subject)
                .verify.draftMessageExists(scenario.subject)
        }
    }
    
    func testSearchForNonExistentMessage() {
        let title = "This message doesn't exist!"

        runTestWithScenario(.pgpmime) {
            InboxRobot()
                .searchBar()
                .searchMessageText(title)
                .verify.noResultsTextIsDisplayed()
        }

    }
}
