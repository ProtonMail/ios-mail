// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import XCTest

final class NotificationsRegistrarMock: NotificationRegistrar {
    var shouldForceReportAllWasSet: Bool = false
    var shouldForceReportAll: Bool = false {
        didSet {
            shouldForceReportAllWasSet = true
        }
    }
    var registerForRemoteNotificationsWasCalled: Bool = false
    func registerForRemoteNotifications() {
        registerForRemoteNotificationsWasCalled = true
    }
}

final class TimestampProviderMock: PushTimestampProvider {
    var _lastReceivedPushTimestampValue: String!
    var lastReceivedPushTimestamp: String {
        _lastReceivedPushTimestampValue
    }
}

class AppVersionDebugViewModelTests: XCTestCase {
    var notificationsRegistrarMock: NotificationsRegistrarMock!
    var pushTimestampProvider: TimestampProviderMock!
    var sut: AppVersionDebugViewModel!

    override func setUp() {
        super.setUp()
        notificationsRegistrarMock = NotificationsRegistrarMock()
        pushTimestampProvider = TimestampProviderMock()
        sut = AppVersionDebugViewModel(notificationsRegistrar: notificationsRegistrarMock, timestampProvider: pushTimestampProvider)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        pushTimestampProvider = nil
        notificationsRegistrarMock = nil
    }

    func testRowValueForPushShouldReturnProperlyFormattedDateFromTimestamp() {
        let sampleDate = Date(timeIntervalSince1970: Double.random(in: 0..<1000000))
        pushTimestampProvider._lastReceivedPushTimestampValue = String(Int(sampleDate.timeIntervalSince1970))
        let df = DateFormatter()
        df.calendar = Calendar.current
        df.dateStyle = .short
        df.timeStyle = .medium
        let formattedDate = df.string(from: sampleDate)
        XCTAssertEqual(sut.rowValue(for: .push), formattedDate)
    }

    func testRegisteringAgainForNotificationShouldSetForReportFlagToTrue() {
        sut.registerAgainForNotifications()
        XCTAssert(notificationsRegistrarMock.shouldForceReportAllWasSet)
        XCTAssert(notificationsRegistrarMock.shouldForceReportAll)
    }

    func testRegisteringAgainForNotificationShouldCallRegisterForRemoteNotifications() {
        sut.registerAgainForNotifications()
        XCTAssert(notificationsRegistrarMock.registerForRemoteNotificationsWasCalled)
    }
    
}
