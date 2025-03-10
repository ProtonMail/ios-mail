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

import Testing
import UserNotifications

final class NotificationAuthorizationStoreTests {
    private let sut: NotificationAuthorizationStore
    private let userDefaults: UserDefaults
    private let userDefaultsSuiteName = UUID().uuidString
    private let userNotificationCenter = UserNotificationCenterSpy()

    init() {
        userDefaults = .init(suiteName: userDefaultsSuiteName).unsafelyUnwrapped
        sut = .init(userDefaults: userDefaults, userNotificationCenter: userNotificationCenter)
    }

    deinit {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    @Test
    func whenNotificationAuthorizationStatusIsNotDeterminedAndHasntBeenRequestedBefore_thenShouldRequestAuthorization() async {
        userNotificationCenter.stubbedAuthorizationStatus = .notDetermined

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == true)
    }

    @Test
    func whenNotificationAuthorizationStatusIsNotDeterminedButHasBeenRequestedBefore_thenShouldNotRequestAuthorization() async {
        await sut.userDidRespondToAuthorizationRequest(accepted: false)

        userNotificationCenter.stubbedAuthorizationStatus = .notDetermined

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == false)
    }

    @Test("Does not request authorization if status is determined", arguments: [UNAuthorizationStatus.authorized, .denied])
    func whenNotificationAuthorizationStatusIsDetermined_thenShouldNotRequestAuthorization(status: UNAuthorizationStatus) async {
        userNotificationCenter.stubbedAuthorizationStatus = status

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == false)
    }

    @Test
    func givenAuthorizationHasBeenRequestedOnce_whenMessageIsSentAfter10Days_thenShouldNotRequestAuthorization() async {
        userNotificationCenter.stubbedAuthorizationStatus = .notDetermined

        userDefaults[.notificationAuthorizationRequestDates] = [
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: -10, to: .now)!
        ]

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == false)
    }

    @Test
    func givenAuthorizationHasBeenRequestedOnce_whenMessageIsSentAfter20Days_thenShouldRequestAuthorization() async {
        userNotificationCenter.stubbedAuthorizationStatus = .notDetermined

        userDefaults[.notificationAuthorizationRequestDates] = [
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: -20, to: .now)!
        ]

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == true)
    }

    @Test
    func givenAuthorizationHasBeenRequestedTwice_whenMessageIsSentAfter20Days_thenShouldNotRequestAuthorization() async {
        userNotificationCenter.stubbedAuthorizationStatus = .notDetermined

        userDefaults[.notificationAuthorizationRequestDates] = [
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: -20, to: .now)!,
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: -10, to: .now)!
        ]

        #expect(await sut.shouldRequestAuthorization(trigger: .messageSent) == false)
    }

    @Test
    func whenUserDeniesAuthorization_thenDoesNotRequestAuthorization() async {
        await sut.userDidRespondToAuthorizationRequest(accepted: false)

        #expect(userNotificationCenter.requestAuthorizationInvocations.isEmpty)
    }

    @Test
    func whenUserGrantsAuthorization_thenRequestsAuthorization() async {
        await sut.userDidRespondToAuthorizationRequest(accepted: true)

        #expect(userNotificationCenter.requestAuthorizationInvocations == [[.alert, .badge, .sound]])
    }
}
