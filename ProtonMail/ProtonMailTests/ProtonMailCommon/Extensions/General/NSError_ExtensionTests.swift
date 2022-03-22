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

final class NSError_ExtensionTests: XCTestCase {
    func testConvenienceInit() {
        let error = NSError(domain: "test.com", code: 50, localizedDescription: "description", localizedFailureReason: "Failure reason", localizedRecoverySuggestion: "suggestion")
        XCTAssertEqual(error.domain, "test.com")
        XCTAssertEqual(error.code, 50)
        XCTAssertEqual(error.localizedDescription, "description")
        XCTAssertEqual(error.localizedFailureReason, "Failure reason")
        XCTAssertEqual(error.localizedRecoverySuggestion, "suggestion")
    }

    func testProtonMailError() {
        let error = NSError.protonMailError(33, localizedDescription: "mail description", localizedFailureReason: "mail failure", localizedRecoverySuggestion: "mail suggestion")
        XCTAssertEqual(error.domain, Bundle.main.bundleIdentifier)
        XCTAssertEqual(error.code, 33)
        XCTAssertEqual(error.localizedDescription, "mail description")
        XCTAssertEqual(error.localizedFailureReason, "mail failure")
        XCTAssertEqual(error.localizedRecoverySuggestion, "mail suggestion")
    }

    func testErrorDomain() {
        let basic = Bundle.main.bundleIdentifier ?? "ch.protonmail"
        let domain1 = NSError.protonMailErrorDomain("unittest")
        XCTAssertEqual(domain1, basic + ".unittest")

        let domain2 = NSError.protonMailErrorDomain()
        XCTAssertEqual(domain2, basic)
    }

    func testInternetError() {
        let codes = [-1009, -1004, -1001]
        for code in codes {
            let error = NSError(domain: "", code: code, userInfo: [:])
            XCTAssertTrue(error.isInternetError())
        }

        let error = NSError(domain: "", code: 100, userInfo: [:])
        XCTAssertFalse(error.isInternetError())

        let response = HTTPURLResponse(statusCode: 99)
        let info = ["com.alamofire.serialization.response.error.response": response]
        let error2 = NSError(domain: "", code: Int.max, userInfo: info)
        XCTAssertFalse(error2.isInternetError())
    }

    func testIsBadVersion() {
        let codes = [5003, 5005]
        for code in codes {
            let error = NSError(domain: "", code: code, userInfo: [:])
            XCTAssertTrue(error.isBadVersionError)
        }

        let error = NSError(domain: "", code: 100, userInfo: [:])
        XCTAssertFalse(error.isBadVersionError)
    }
}
