// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import XCTest

class ViewMessagesTests: FixtureAuthenticatedTestCase {

    func testOpenMessageWithRichText() {
        runTestWithScenario(.qaMail002) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .verify.messageBodyWithStaticTextExists(scenario.body)
        }
    }
    
    func testOpenMessageWithEmptyBody() {
        runTestWithScenario(.qaMail003) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .verify.messageBodyWithStaticTextExists(scenario.body)
        }
    }
    
    func testOpenMessageWithLink() {
        runTestWithScenario(.qaMail005) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .verify.messageBodyWithLinkExists(scenario.body)
        }
    }
    
    func testOpenMessageWithEmailTrackers() {
        let bounceexchange = "bounceexchange.com"
        let trackerStaticTextLabel = "31 email trackers blocked"
        let messageSubject = "014_2_messages_with_remote_content_1_message_with_tracking_in_inbox"
        runTestWithScenario(.qaMail014) {
            InboxRobot()
                .clickMessageBySubject(messageSubject)
                .clickFilledEmailTrackerShieldIcon()
                .clickTrackerRowWithLabel(trackerStaticTextLabel)
                .clickOnTrackerWithLabel(bounceexchange)
                .verify.trackerCountByLabelIs(label: bounceexchange, count: 1)
                .verify.trackerCellIsShown(name:  "https://bounceexchange.com/tag/em/1990.gif")
        }
    }
    
    func testOpenMessageWithAttachment() {
        runTestWithScenario(.trashMultipleMessages) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .clickAttachmentsText("2 attachments(2 KB)")
                .verify.attachmentWithNameExist("next.svg")
        }
    }
    
    func testMarkConversationAsUnreadFromMessageView() {
        runTestWithScenario(.qaMail002) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .waitForMessageBodyWithTextToExist(text: "Auto generated email")
                .navigateBackToInbox()
                .verify.messageWithSubjectIsRead(scenario.subject)
                .clickMessageBySubject(scenario.subject)
                .waitForMessageBodyWithTextToExist(text: "Auto generated email")
                .clickMarkAsUnreadIcon()
                .verify.messageWithSubjectIsUnread(scenario.subject)
        }
    }
}
