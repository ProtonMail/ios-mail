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

    var reachabilityStub: ReachabilityStub!

    override func setUp() {
        super.setUp()

        self.reachabilityStub = ReachabilityStub()
        Environment.locale = { .enUS }
    }

    override func tearDown() {
        super.tearDown()
        
        self.reachabilityStub = nil
        Environment.restore()
    }

    func testGetReferenceTimeFromExtension() {
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(reachability: nil, processInfo: processInfo, deviceDate: Date())
        let calServerTime = Date(timeIntervalSince1970: 1635745851 + 200)
        // 1. Extension
        // 2. Device doesn't reboot
        // Should return reference time by local server time and systemUpTime
        XCTAssertEqual(calServerTime, ref)
    }

    func testGetReferenceTimeWhenDeviceOffline() {
        self.reachabilityStub.currentReachabilityStatusStub = .NotReachable

        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(reachability: self.reachabilityStub, processInfo: processInfo, deviceDate: Date())
        let calServerTime = Date(timeIntervalSince1970: 1635745851 + 200)
        // 1. NotReachable
        // 2. Device doesn't reboot
        // Should return reference time by local server time and systemUpTime
        XCTAssertEqual(calServerTime, ref)
    }

    func testGetReferenceTimeWhenDeviceOfflineAndReboot_serverTimer_newer() {
        self.reachabilityStub.currentReachabilityStatusStub = .NotReachable

        let deviceTime = Date(timeIntervalSince1970: 1625745851)
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(10)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(reachability: self.reachabilityStub, processInfo: processInfo, deviceDate: deviceTime)
        // 1. NotReachable
        // 2. Device reboot
        // Should compare local server time and the device time and return the newer one
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testGetReferenceTimeWhenDeviceOfflineAndReboot_deviceTime_newer() {
        self.reachabilityStub.currentReachabilityStatusStub = .NotReachable

        let deviceTime = Date(timeIntervalSince1970: 1665745851)
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(10)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let ref = Date.getReferenceDate(reachability: self.reachabilityStub, processInfo: processInfo, deviceDate: deviceTime)
        // 1. NotReachable
        // 2. Device reboot
        // Should compare local server time and the device time and return the newer one
        XCTAssertEqual(deviceTime, ref)
    }

    func testGetReferenceTimeWhenDeviceHasWifi() {
        self.reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)
        let ref = Date.getReferenceDate(reachability: self.reachabilityStub, processInfo: processInfo, deviceDate: Date())
        // If the device is online
        // It should always return server time
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testGetReferenceTimeWhenDeviceHasWWAN() {
        self.reachabilityStub.currentReachabilityStatusStub = .ReachableViaWWAN
        let serverTime = TimeInterval(1635745851)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)
        let ref = Date.getReferenceDate(reachability: self.reachabilityStub, processInfo: processInfo, deviceDate: Date())
        // If the device is online
        // It should always return server time
        XCTAssertEqual(Date(timeIntervalSince1970: serverTime), ref)
    }

    func testCountExpirationTimeMinuteLevel() {
        self.reachabilityStub.currentReachabilityStatusStub = .ReachableViaWWAN

        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 120.0)
        let result = time.countExpirationTime(processInfo: processInfo, reachability: self.reachabilityStub)
        XCTAssertEqual(result, "3 mins")
    }

    func testCountExpirationTimeHourLevel() {
        self.reachabilityStub.currentReachabilityStatusStub = .ReachableViaWWAN

        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 7200.0)
        let result = time.countExpirationTime(processInfo: processInfo, reachability: self.reachabilityStub)
        XCTAssertEqual(result, "2 hours")
    }

    func testCountExpirationTimeDayLevel() {
        self.reachabilityStub.currentReachabilityStatusStub = .ReachableViaWWAN

        let interval: Int64 = 1635745851
        let serverTime = TimeInterval(interval)
        let localSystemUpTime = TimeInterval(2000)
        let systemUpTime = TimeInterval(2200)
        let processInfo = SystemUpTimeMock(localServerTime: serverTime, localSystemUpTime: localSystemUpTime, systemUpTime: systemUpTime)

        let time = Date(timeIntervalSince1970: Double(interval) + 86500.0)
        let result = time.countExpirationTime(processInfo: processInfo, reachability: self.reachabilityStub)
        XCTAssertEqual(result, "1 day")
    }
}

extension Date_ExtensionTests {
    func testFormattedWith() {
        let date = Date(timeIntervalSince1970: 1641979189)
        guard let timeZone = TimeZone(secondsFromGMT: 0) else {
            XCTFail()
            return
        }
        XCTAssertEqual(date.formattedWith("yyyy, MM, dd, HH, mm, ss", timeZone: timeZone), "2022, 01, 12, 09, 19, 49")
    }
}
