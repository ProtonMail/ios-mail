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

    func testSetup_inDebug() {
        sut.setup(isInDebug: true, environment: .production)
        XCTAssertFalse(sut.isEnabled)
    }

    func testSetup_notInDebug_isProduction() throws {
        sut.setup(isInDebug: false, environment: .production)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(analyticsMock.environment, "production")
        let isDebug = try XCTUnwrap(analyticsMock.debug)
        XCTAssertFalse(isDebug)
    }

    func testSetup_notInDebug_isEnterprise() throws {
        sut.setup(isInDebug: false, environment: .enterprise)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(analyticsMock.environment, "enterprise")
        let isDebug = try XCTUnwrap(analyticsMock.debug)
        XCTAssertFalse(isDebug)
    }

    func testTrackEvent() {
        sut.setup(isInDebug: false, environment: .production)
        sut.sendEvent(.userKickedOut(reason: .apiAccessTokenInvalid))
        XCTAssertEqual(analyticsMock.event, .userKickedOut(reason: .apiAccessTokenInvalid))
    }

    func testSendDebugMessage_notEnable() {
        sut.sendEvent(.userKickedOut(reason: .apiAccessTokenInvalid))
        XCTAssertNil(analyticsMock.event)
    }

    func testSendErrorMessage() {
        sut.setup(isInDebug: false, environment: .production)
        sut.sendError(.coreDataInitialisation(error: "error desc"))
        XCTAssertEqual(analyticsMock.errorEvent, .coreDataInitialisation(error: "error desc"))
    }

    func testSendErrorMessage_notEnable() {
        sut.sendError(.coreDataInitialisation(error: "error desc"))
        XCTAssertNil(analyticsMock.errorEvent)
    }
}
