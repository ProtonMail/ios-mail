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
import InboxComposer
import InboxCore
import InboxSnapshotTesting
import InboxTesting
import Testing

@Suite(.currentDate(.fixture("2025-02-07 09:32:00")))
class MessageBannersViewSnapshotTests {
    var scheduleDateFormatter: ScheduleSendDateFormatter {
        .init(locale: DateEnvironment.calendar.locale!, timeZone: DateEnvironment.calendar.timeZone)
    }
    var tomorrowAt8AM: UInt64 {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        components.second = 0
        let tomorrow = DateEnvironment.calendar.nextDate(after: .now, matching: components, matchingPolicy: .nextTime)!
        return UInt64(tomorrow.timeIntervalSince1970)
    }

    @MainActor
    @Test
    func testMessageBannersViewFirstVariantLayoutsCorrectly() {
        let bannersView = MessageBannersView(
            types: [
                .blockedSender,
                .phishingAttempt(auto: true),
                .expiry(timestamp: 1_740_238_200),
                .autoDelete(timestamp: 1_740_670_200),
                .unsubscribeNewsletter,
                .embeddedImages,
                .scheduledSend(timestamp: tomorrowAt8AM),
            ],
            timer: Timer.self,
            scheduleSendDateFormatter: scheduleDateFormatter,
            action: { _ in }
        )

        assertSnapshotsOnIPhoneX(of: bannersView)
    }

    @MainActor
    @Test(.calendarZurichEnUS)
    func testMessageBannersViewSecondVariantLayoutsCorrectly() async throws {
        let bannersView = MessageBannersView(
            types: [
                .blockedSender,
                .spam(auto: true),
                .expiry(timestamp: 1_738_920_762),
                .scheduledSend(timestamp: 1_905_004_876),
                .snoozed(timestamp: 1_740_238_200),
                .remoteContent,
            ],
            timer: Timer.self,
            scheduleSendDateFormatter: scheduleDateFormatter,
            action: { _ in }
        )

        assertSnapshotsOnIPhoneX(of: bannersView)
    }
}
