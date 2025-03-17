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

import UserNotifications

@testable import ProtonMail

final class UserNotificationCenterSpy: UserNotificationCenter {
    var delegate: UNUserNotificationCenterDelegate?
    var stubbedAuthorizationResult = true
    var stubbedAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    private(set) var requestAuthorizationInvocations: [UNAuthorizationOptions] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationInvocations.append(options)

        return stubbedAuthorizationResult
    }
}
