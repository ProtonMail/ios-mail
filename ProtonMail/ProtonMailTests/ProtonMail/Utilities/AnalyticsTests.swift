// Copyright (c) 2022 Proton AG
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
import ProtonMailAnalytics

class AnalyticsTests: XCTestCase {

    var sut: Analytics!
    var analyticsMock: MockProtonMailAnalytics!

    override func setUp() {
        super.setUp()
        analyticsMock = MockProtonMailAnalytics(endPoint: "entryPoint")
        sut = Analytics(analytics: analyticsMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        analyticsMock = nil
    }

    func testSetup_notInDebug_isProduction() throws {
        sut.setup(environment: .production, reportCrashes: true, telemetry: true)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(analyticsMock.environment, "production")
        let isDebug = try XCTUnwrap(analyticsMock.debug)
        XCTAssertFalse(isDebug)
    }

    func testSendEvent_whenSetupCalled_shouldSendTheEventSuccessfully() {
        sut.setup(environment: .production, reportCrashes: true, telemetry: true)
        sut.sendEvent(.userKickedOut(reason: .apiAccessTokenInvalid))
        XCTAssertEqual(analyticsMock.event, .userKickedOut(reason: .apiAccessTokenInvalid))
    }

    func testSendEvent_whenSetupNotCalled_shouldNotSendTheEvent() {
        sut.sendEvent(.userKickedOut(reason: .apiAccessTokenInvalid))
        XCTAssertNil(analyticsMock.event)
    }

    func testSendEvent_whenDisabled_shouldNotSendTheEvent() {
        sut.setup(environment: .production, reportCrashes: true, telemetry: false)
        sut.sendEvent(.userKickedOut(reason: .apiAccessTokenInvalid))
        XCTAssertNil(analyticsMock.event)
    }

    func testSendError_whenSetupCalled_shouldSendTheErrorSuccessfully() {
        sut.setup(environment: .production, reportCrashes: true, telemetry: true)
        sut.sendError(.sendMessageFail(error: "error desc"))
        XCTAssertEqual(analyticsMock.errorEvent, .sendMessageFail(error: "error desc"))
    }

    func testSendError_whenSetupNotCalled_shouldNotSendTheError() {
        sut.sendError(.sendMessageFail(error: "error desc"))
        XCTAssertNil(analyticsMock.errorEvent)
    }

    func testSendError_whenDisabled_shouldNotSendTheError() {
        sut.setup(environment: .production, reportCrashes: true, telemetry: false)
        sut.sendError(.sendMessageFail(error: "error desc"))
        XCTAssertNil(analyticsMock.errorEvent)
    }
}
