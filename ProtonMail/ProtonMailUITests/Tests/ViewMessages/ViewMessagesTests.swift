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
import ProtonCore_TestingToolkit

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
        runTestWithScenario(.qaMail014) {
            InboxRobot()
                .clickMessageByIndex(1)
                .clickFilledEmailTrackerShieldIcon()
                .clickEmailTrackerShevronImage()
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
}
