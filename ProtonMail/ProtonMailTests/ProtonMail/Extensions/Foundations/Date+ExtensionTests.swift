// Copyright (c) 2021 Proton AG
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
@testable import ProtonMail

final class Date_ExtensionTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        LocaleEnvironment.restore()
    }

    func testTomorrow() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let checker = DateFormatter()
        checker.dateFormat = "yyyy-MM-dd HH:mm"

        var date = try XCTUnwrap(formatter.date(from: "2022-04-19"))
        var tomorrow = try XCTUnwrap(date.tomorrow(at: 4, minute: 27))
        var ans = try XCTUnwrap(checker.string(from: tomorrow))
        XCTAssertEqual(ans, "2022-04-20 04:27")

        date = try XCTUnwrap(formatter.date(from: "2022-04-30"))
        tomorrow = try XCTUnwrap(date.tomorrow(at: 18, minute: 3))
        ans = try XCTUnwrap(checker.string(from: tomorrow))
        XCTAssertEqual(ans, "2022-05-01 18:03")

        date = try XCTUnwrap(formatter.date(from: "2022-02-28"))
        tomorrow = try XCTUnwrap(date.tomorrow(at: 18, minute: 3))
        ans = try XCTUnwrap(checker.string(from: tomorrow))
        XCTAssertEqual(ans, "2022-03-01 18:03")
    }

    func testNextWeekday() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let checker = DateFormatter()
        checker.dateFormat = "yyyy-MM-dd HH:mm"

        var date = try XCTUnwrap(formatter.date(from: "2022-04-19"))
        var next = try XCTUnwrap(date.next(.monday, hour: 12, minute: 22))
        var ans = try XCTUnwrap(checker.string(from: next))
        XCTAssertEqual(ans, "2022-04-25 12:22")

        date = try XCTUnwrap(formatter.date(from: "2022-04-19"))
        next = try XCTUnwrap(date.next(.tuesday, hour: 12, minute: 22))
        ans = try XCTUnwrap(checker.string(from: next))
        XCTAssertEqual(ans, "2022-04-26 12:22")

        date = try XCTUnwrap(formatter.date(from: "2022-02-28"))
        next = try XCTUnwrap(date.next(.wednesday, hour: 12, minute: 22))
        ans = try XCTUnwrap(checker.string(from: next))
        XCTAssertEqual(ans, "2022-03-02 12:22")
    }

    func testGetReferenceTimeWhenDeviceOffline() {
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(connectionStatus: .notConnected, processInfo: processInfo, deviceDate: Date())
        let calServerTime = Date(timeIntervalSince1970: 1635745851 + 200)
        // 1. NotReachable
        // 2. Device doesn't reboot
        // Should return reference time by local server time and systemUpTime
        XCTAssertEqual(calServerTime, ref)
    }

    func testGetReferenceTimeWhenDeviceOfflineAndReboot_serverTimer_newer() {
        let deviceTime = Date(timeIntervalSince1970: 1625745851)
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(10)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(connectionStatus: .notConnected, processInfo: processInfo, deviceDate: deviceTime)
        // 1. NotReachable
        // 2. Device reboot
        // Should compare local server time and the device time and return the newer one
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testGetReferenceTimeWhenDeviceOfflineAndReboot_deviceTime_newer() {
        let deviceTime = Date(timeIntervalSince1970: 1665745851)
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(10)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(connectionStatus: .notConnected, processInfo: processInfo, deviceDate: deviceTime)
        // 1. NotReachable
        // 2. Device reboot
        // Should compare local server time and the device time and return the newer one
        XCTAssertEqual(deviceTime, ref)
    }

    func testGetReferenceTimeWhenDeviceHasWifi() {
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)
        let ref = Date.getReferenceDate(connectionStatus: .connectedViaWiFi, processInfo: processInfo, deviceDate: Date())
        // If the device is online
        // It should always return server time
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testGetReferenceTimeWhenDeviceHasWWAN() {
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)
        let ref = Date.getReferenceDate(connectionStatus: .connectedViaCellular, processInfo: processInfo, deviceDate: Date())
        // If the device is online
        // It should always return server time
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testCountExpirationTimeMinuteLevel() {
        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 120.0)
        let result = time.countExpirationTime(connectionStatus: .connected, processInfo: processInfo)
        XCTAssertEqual(result, "2 minutes")
    }

    func testCountExpirationTimeHourLevel() {
        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 7200.0)
        let result = time.countExpirationTime(processInfo: processInfo)
        XCTAssertEqual(result, "2 hours")
    }

    func testCountExpirationTimeDayLevel() {
        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 86500.0)
        let result = time.countExpirationTime(processInfo: processInfo)
        XCTAssertEqual(result, "1 day")
    }

    func testAddingDate() throws {
        let date = Date()
        let dateInterval = date.timeIntervalSince1970
        var result = date.add(.minute, value: 1)
        var timeInterval = try XCTUnwrap(result?.timeIntervalSince1970)
        XCTAssertEqual(timeInterval - dateInterval, 60)

        result = date.add(.hour, value: -1)
        timeInterval = try XCTUnwrap(result?.timeIntervalSince1970)
        XCTAssertEqual(dateInterval - timeInterval, 60 * 60)
    }

    func testFormat_12H() {
        let date = Date(timeIntervalSince1970: 1671187872)
        if #available(iOS 17.0, *) {
            XCTAssertEqual(date.localizedString(), "Dec 16 at 10:51 AM")
        } else {
            XCTAssertEqual(date.localizedString(), "Dec 16 at 10:51 AM")
        }
    }

    func testFormat_24H_with_template() {
        LocaleEnvironment.locale = { .frGP }
        let date = Date(timeIntervalSince1970: 1671187872)
        XCTAssertEqual(date.localizedString(), "16 déc. à 10:51")
    }

    func testToday() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let checker = DateFormatter()
        checker.dateFormat = "yyyy-MM-dd HH:mm"

        let date = try XCTUnwrap(formatter.date(from: "2023-02-10"))
        let result = try XCTUnwrap(date.today(at: 8, minute: 0))

        let resultText = try XCTUnwrap(checker.string(from: result))
        XCTAssertEqual(resultText, "2023-02-10 08:00")
    }
}

extension Date_ExtensionTests {
    func testFormattedWith() throws {
        let date = Date(timeIntervalSince1970: 1641979189)
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        XCTAssertEqual(date.formattedWith("yyyy, MM, dd, HH, mm, ss", timeZone: timeZone), "2022, 01, 12, 09, 19, 49")
    }
}
