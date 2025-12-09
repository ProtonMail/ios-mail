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

import InboxTesting
import Testing

@testable import ProtonMail

@MainActor
final class RatingBoosterTests {
    private let sut: RatingBooster
    private let userSession = MailUserSessionSpy(id: "")
    private let clock = QuickenedClock(speedupFactor: 10)

    private var reviewRequests = 0

    init() {
        sut = .init(userSession: userSession, clock: clock)

        sut.requestReview = { [unowned self] in
            reviewRequests += 1
        }
    }

    @Test
    func givenUserIsTargeted_whenViewingMailboxSecondTime_thenRequestsReview() async throws {
        userSession.enabledFeatures.insert(LegacyFeatureFlag.ratingBooster)

        try await sut.feed(navigationPath: .init())
        try await sut.feed(navigationPath: .init("mailbox item"))
        try await sut.feed(navigationPath: .init())

        #expect(reviewRequests == 1)
    }

    @Test
    func givenUserIsTargeted_whenViewingMailboxMultipleTimes_thenDoesntRequestMoreReviews() async throws {
        userSession.enabledFeatures.insert(LegacyFeatureFlag.ratingBooster)

        try await sut.feed(navigationPath: .init())
        try await sut.feed(navigationPath: .init("mailbox item"))
        try await sut.feed(navigationPath: .init())
        try await sut.feed(navigationPath: .init("mailbox item"))
        try await sut.feed(navigationPath: .init())

        #expect(reviewRequests == 1)
    }

    @Test
    func givenUserIsTargeted_whenComingBackFromQuicklyOpenedPushNotification_thenDoesntRequestReview() async throws {
        userSession.enabledFeatures.insert(LegacyFeatureFlag.ratingBooster)

        try await sut.feed(navigationPath: .init("push notification item"))
        try await sut.feed(navigationPath: .init())

        #expect(reviewRequests == 0)
    }

    @Test
    func givenUserIsTargeted_whenOpeningPushNotificationWhileOnMessageView_thenDoesntRequestReview() async throws {
        userSession.enabledFeatures.insert(LegacyFeatureFlag.ratingBooster)

        try await sut.feed(navigationPath: .init())
        try await sut.feed(navigationPath: .init("mailbox item"))

        Task {
            try await sut.feed(navigationPath: .init())
        }

        try await clock.sleep(for: MailboxModel.estimatedBackNavigationDuration)
        try await sut.feed(navigationPath: .init("push notification item"))

        #expect(reviewRequests == 0)
    }

    @Test
    func givenUserIsNotTargeted_whenViewingMailboxSecondTime_thenDoesntRequestReview() async throws {
        try await sut.feed(navigationPath: .init())
        try await sut.feed(navigationPath: .init("mailbox item"))
        try await sut.feed(navigationPath: .init())

        #expect(reviewRequests == 0)
    }
}

private struct QuickenedClock: Clock {
    private let wrappedClock = ContinuousClock()
    private let speedupFactor: Int

    init(speedupFactor: Int) {
        self.speedupFactor = speedupFactor
    }

    var now: ContinuousClock.Instant {
        wrappedClock.now
    }

    var minimumResolution: ContinuousClock.Duration {
        wrappedClock.minimumResolution
    }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        let sleepingDuration = deadline - now
        try await wrappedClock.sleep(for: sleepingDuration / speedupFactor)
    }
}
