// Copyright (c) 2025 Proton Technologies AG
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

@testable import ProtonMail
import InboxCore
import InboxDesignSystem
import InboxSnapshotTesting
import InboxTesting
import XCTest

class MessageBannersViewSnapshotTests: BaseTestCase {
    
    var originalCurrentDate: (() -> Date)!
    
    override func setUp() {
        super.setUp()
        originalCurrentDate = DateEnvironment.currentDate
        DateEnvironment.currentDate = { .fixture("2025-02-07 09:32:00") }
    }
    
    override func tearDown() {
        DateEnvironment.currentDate = originalCurrentDate
        super.tearDown()
    }
    
    func testMessageBannersViewFirstVariantLayoutsCorrectly() {
        let bannersView = MessageBannersView(types: [
            .blockedSender,
            .phishingAttempt,
            .expiry(timestamp: 1_740_238_200),
            .autoDelete(timestamp: 1_740_238_200),
            .unsubscribeNewsletter,
            .embeddedImages
        ])
        
        assertSnapshotsOnIPhoneX(of: bannersView)
    }
    
    func testMessageBannersViewSecondVariantLayoutsCorrectly() {
        let bannersView = MessageBannersView(types: [
            .blockedSender,
            .spam,
            .scheduledSend(timestamp: 1_740_238_200),
            .snoozed(timestamp: 1_740_238_200),
            .remoteContent
        ])
        
        assertSnapshotsOnIPhoneX(of: bannersView)
    }

}
