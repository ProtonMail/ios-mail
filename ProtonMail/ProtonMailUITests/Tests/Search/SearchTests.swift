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
    
    func testSearchFromInboxByAddress() {
        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .searchBar()
                .searchMessageText(user!.email)
                .verify.messageExists(user!.email)
        }
    }
    
    func testSearchDraft() {
        runTestWithScenario(.pgpinlineDrafts) {
            InboxRobot()
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
