// Copyright (c) 2022 Proton Technologies AG
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

import XCTest
@testable import ProtonMail

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
        sut.setup(isInDebug: true, isProduction: true)
        XCTAssertFalse(sut.isEnabled)
    }

    func testSetup_notInDebug_isProduction() throws {
        sut.setup(isInDebug: false, isProduction: true)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(analyticsMock.environment, "production")
        let isDebug = try XCTUnwrap(analyticsMock.debug)
        XCTAssertFalse(isDebug)
    }

    func testSetup_notInDebug_isEnterprise() throws {
        sut.setup(isInDebug: false, isProduction: false)
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(analyticsMock.environment, "enterprise")
        let isDebug = try XCTUnwrap(analyticsMock.debug)
        XCTAssertFalse(isDebug)
    }

    func testSendDebugMessage() {
        sut.setup(isInDebug: false, isProduction: true)

        let testExtra: [String: Any] = ["Test": 1]
        sut.debug(message: .authError,
                  extra: testExtra,
                  file: "file1",
                  function: "function1",
                  line: 998,
                  column: 123)
        XCTAssertEqual(analyticsMock.debugEvent, .authError)
        XCTAssertNotNil(analyticsMock.debugExtra)
        XCTAssertEqual(analyticsMock.debugFile, "file1")
        XCTAssertEqual(analyticsMock.debugFunction, "function1")
        XCTAssertEqual(analyticsMock.debugLine, 998)
        XCTAssertEqual(analyticsMock.debugColum, 123)
    }

    func testSendDebugMessage_notEnable() {
        let testExtra: [String: Any] = ["Test": 1]
        sut.debug(message: .authError,
                  extra: testExtra,
                  file: "file1",
                  function: "function1",
                  line: 998,
                  column: 123)
        XCTAssertNil(analyticsMock.debugEvent)
        XCTAssertNil(analyticsMock.debugExtra)
        XCTAssertNil(analyticsMock.debugFile)
        XCTAssertNil(analyticsMock.debugFunction)
        XCTAssertNil(analyticsMock.debugLine)
        XCTAssertNil(analyticsMock.debugColum)
    }

    func testSendErrorMessage() {
        sut.setup(isInDebug: false, isProduction: true)

        let testExtra: [String: Any] = ["Test": 1]
        let testError = NSError.lockError()
        sut.error(message: .decryptedMessageBodyFailed,
                  error: testError,
                  extra: testExtra,
                  file: "file1",
                  function: "function1",
                  line: 986,
                  column: 123)

        XCTAssertEqual(analyticsMock.errorEvent, .decryptedMessageBodyFailed)
        XCTAssertNotNil(analyticsMock.errorError)
        XCTAssertNotNil(analyticsMock.errorExtra)
        XCTAssertEqual(analyticsMock.errorFile, "file1")
        XCTAssertEqual(analyticsMock.errorFunction, "function1")
        XCTAssertEqual(analyticsMock.errorLine, 986)
        XCTAssertEqual(analyticsMock.errorColum, 123)
    }

    func testSendErrorMessage_notEnable() {
        let testExtra: [String: Any] = ["Test": 1]
        let testError = NSError.lockError()
        sut.error(message: .decryptedMessageBodyFailed,
                  error: testError,
                  extra: testExtra,
                  file: "file1",
                  function: "function1",
                  line: 986,
                  column: 123)

        XCTAssertNil(analyticsMock.errorEvent)
        XCTAssertNil(analyticsMock.errorError)
        XCTAssertNil(analyticsMock.errorExtra)
        XCTAssertNil(analyticsMock.errorFile)
        XCTAssertNil(analyticsMock.errorFunction)
        XCTAssertNil(analyticsMock.errorLine)
        XCTAssertNil(analyticsMock.errorColum)
    }
}
