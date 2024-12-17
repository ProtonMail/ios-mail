// Copyright (c) 2024 Proton Technologies AG
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
import XCTest

final class AppIconBadgeServiceTests: XCTestCase {
    private var sut: AppIconBadgeService!
    private var userNotificationCenter: UserNotificationCenterSpy!
    private var stubbedUnreadCount: UInt64!

    override func setUp() {
        super.setUp()

        userNotificationCenter = .init()

        sut = .init(userNotificationCenter: userNotificationCenter) { [unowned self] in
            self.stubbedUnreadCount
        }
    }

    override func tearDown() {
        sut = nil
        userNotificationCenter = nil

        super.tearDown()
    }

    func testOnAppLaunch_requestsNotificationAuthorizationForBadgeOnly() async {
        await sut.setUpServiceAsync()
        XCTAssertEqual(userNotificationCenter.requestAuthorizationInvocations, [.badge])
    }

    func testWhenTheAppEntersBackground_setsAppIconBadgeToTheUnreadCount() async {
        stubbedUnreadCount = 5

        await sut.enterBackgroundServiceAsync()

        let appIconBadge = await UIApplication.shared.applicationIconBadgeNumber
        XCTAssertEqual(appIconBadge, 5)
    }
}

private class UserNotificationCenterSpy: UserNotificationCenter {
    private(set) var requestAuthorizationInvocations: [UNAuthorizationOptions] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestAuthorizationInvocations.append(options)

        return true
    }

    func setBadgeCount(_ newBadgeCount: Int) async throws {
        // we don't actually need to mock this, we can use the real mechanism
        try await UNUserNotificationCenter.current().setBadgeCount(newBadgeCount)
    }
}
