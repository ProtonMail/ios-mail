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

@testable import ProtonMail

struct NotificationAuthorizationServiceTests {
    private var sut: NotificationAuthorizationService!
    private var remoteNotificationRegistrar: RemoteNotificationRegistrarSpy!

    init() {
        remoteNotificationRegistrar = .init()
        sut = .init(remoteNotificationRegistrar: remoteNotificationRegistrar)
    }

    @Test
    func onAppLaunch_registersForRemoteNotifications() async {
        await sut.setUpServiceAsync()

        #expect(await remoteNotificationRegistrar.isRegisteredForRemoteNotifications)
    }
}

private class RemoteNotificationRegistrarSpy: RemoteNotificationRegistrar {
    private(set) var isRegisteredForRemoteNotifications = false

    func registerForRemoteNotifications() {
        isRegisteredForRemoteNotifications = true
    }
}
