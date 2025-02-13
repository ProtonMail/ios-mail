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

import Testing
import UserNotifications

@testable import ProtonMail

struct NotificationAuthorizationServiceTests {
    private var sut: NotificationAuthorizationService!
    private var remoteNotificationRegistrar: RemoteNotificationRegistrarSpy!
    private var userNotificationCenter: UserNotificationCenterSpy!

    init() {
        remoteNotificationRegistrar = .init()
        userNotificationCenter = .init()
        sut = .init(remoteNotificationRegistrar: remoteNotificationRegistrar, userNotificationCenter: userNotificationCenter)
    }

    @Test func onAppLaunch_requestsNotificationAuthorization() async throws {
        await sut.setUpServiceAsync()

        #expect(userNotificationCenter.requestAuthorizationInvocations == [[.alert, .badge, .sound]])
    }

    @Test func onAppLaunch_ifNotificationsAuthorized_registersForRemoteNotifications() async throws {
        userNotificationCenter.stubbedAuthorizationResult = true

        await sut.setUpServiceAsync()

        #expect(await remoteNotificationRegistrar.isRegisteredForRemoteNotifications)
    }

    @Test func onAppLaunch_ifNotificationsNotAuthorized_doesNotRegisterForRemoteNotifications() async throws {
        userNotificationCenter.stubbedAuthorizationResult = false

        await sut.setUpServiceAsync()

        #expect(await !remoteNotificationRegistrar.isRegisteredForRemoteNotifications)
    }
}

private class RemoteNotificationRegistrarSpy: RemoteNotificationRegistrar {
    private(set) var isRegisteredForRemoteNotifications = false

    func registerForRemoteNotifications() {
        isRegisteredForRemoteNotifications = true
    }
}

private class UserNotificationCenterSpy: UserNotificationCenter {
    var stubbedAuthorizationResult = true

    private(set) var requestAuthorizationInvocations: [UNAuthorizationOptions] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationInvocations.append(options)

        return stubbedAuthorizationResult
    }
}
