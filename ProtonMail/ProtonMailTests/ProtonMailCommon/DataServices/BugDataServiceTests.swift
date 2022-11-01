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

import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_TestingToolkit
@testable import ProtonMail
import XCTest

final class BugDataServiceTests: XCTestCase {
    private var sut: BugDataService!
    private var apiServiceMock: APIServiceMock!

    override func setUp() {
        super.setUp()
        apiServiceMock = APIServiceMock()
        sut = BugDataService(api: apiServiceMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        apiServiceMock = nil
    }

    func testReportBugSucceeds() throws {
        let bug = "This is a bug message"
        let userName = "Robot"
        let email = "abc@pm.me"
        let lastReceivedPush = String(Date().timeIntervalSince1970)
        let reachability = "WiFi"
        let completionExpectations = expectation(description: "Wait async operation")
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains(BugReportRequest.defaultPath) {
                completion?(nil, ["Code": 1001], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        self.sut.reportBug(bug,
                           username: userName,
                           email: email,
                           lastReceivedPush: lastReceivedPush,
                           reachabilityStatus: reachability) { error in
            XCTAssertNil(error)
            completionExpectations.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(apiServiceMock.requestStub.capturedArguments.last)

        XCTAssertEqual(argument.first, BugReportRequest.defaultMethod)
        let parameters = try XCTUnwrap(argument.a3 as? [String: Any])
        let expectedDescription = bug.appending("\nLP Timestamp:\(lastReceivedPush)").appending("\nReachability:\(reachability)")
        XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.description.rawValue] as! String, expectedDescription)
        XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.userName.rawValue] as! String, userName)
        XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.email.rawValue] as! String, email)
    }

    func testReportBugFailed() {
        let bug = "This is a bug message"
        let userName = "Robot"
        let email = "abc@pm.me"
        let lastReceivedPush = String(Date().timeIntervalSince1970)
        let reachability = "WiFi"
        let stubbedError = NSError(domain: "error.com", code: 1, userInfo: [:])
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains(BugReportRequest.defaultPath) {
                completion?(nil, nil, stubbedError)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }
        let completionExpectations = expectation(description: "Wait async operation")

        self.sut.reportBug(bug,
                           username: userName,
                           email: email,
                           lastReceivedPush: lastReceivedPush,
                           reachabilityStatus: reachability) { error in
            XCTAssertEqual(error, stubbedError)
            completionExpectations.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testReportPhishing_bodyIsArmored_doesNotCallApi() {
        let expectation1 = expectation(description: "Closure is called")
        let messageBody = "-----BEGIN PGP MESSAGE-----\nVersion: ProtonMail\n\nwcBMA0Yq6Y1dFHsbAQgAgMyPrKvZZ9Uj6wK/N0oA22Om+nFYJmTwAPfEc29k\nBp/r+FSAtbBUbKTUPgFwh2OaNyShIDEQDzsZxCMVoCtNs+scmCWJPUl9NfCF\nzrDeTZIoOQZlRooxFF83ZRDQ3uAFyG5SH7mRY+pSc28TmnXDTujsfLxGF516\niVgJZz/LSHgtFP65mCuZfpOOsTG0bDVnaTAZT9X97rF6gmvkaaUqyh5QWmUl\nCqyeOeBlG7WGy4fiiGt0v+gNnkbYMp4De2riBfIPMVy0F+E7yqyzZU8+Z7NZ\n1MA8WomaTjmtZJB9dhq0aIwPMXYoeC7AGJCFjujxr18Syw/nKixy6A90/imb\nl9LBVgH7/Lvk/9r3uJ4WBD756Mjzi7jZWthEmKyi9okcO7Q2Gd6nANF4qVIa\nZ5U0PKLV8h8z8TuYPLWG+ak26jbKNBHl0JuuoKGDcQGvCOUDyRvMHCjdYbo8\nbPEOlFDvHubQ1nXPsAFZBmGJ09i7rmmuszXpONV1MtPJ8HR+O222hH/Dhf+i\nXWGOQMyE4fJ0gbLEsOa5hNvNoxofCb9NKHTJQsJq7Zd6YSQkL0MwIxzxF7ub\nXdH7AEipkcDiFnHBfQZoTabHQd5xDyyj5D8hXyoXSnj0rGd0mtZgSCJTVNdY\nHR13gCjG+fGWEECFOpQ/tlZJ3jFmx3wg0B0j8a9Zi88PIfxObu2CbAiHtpLS\nOcH3YmHprLkemiHR79mi4X+g/5pm2AkrVHtuspfYGvpiHD3/lc4I+YmWa4L5\nGP+jlC0AIIvftjs7Yo4aSR/KdEotxzgvljsPtljJCs527hz0+lv+DTD/vg46\n2y95eAaSjhJcIKmex/l0M+aBkMt9wsIOC188lGmnuFMC4qCELsbLwkqbDeEk\ni4uJ/8u3pAhzt7X+l5pYbu5Qlq/PMxP9SP4wHZ5JlMpDOQlqSPD6z5YYtB4x\nsmZiZsIcBZWAsCkn2kcZyeIUydwtN9QOIJCkFZwDZkHy0h+Xw7CD4CLGPO1e\nZTr7c7zFy8QrC6nbSTuI5cxd9vJLeNcBCRvRffFNFDdSn1tuJ0jIKQRX/A==\n=SZ5u\n-----END PGP MESSAGE-----\n"

        sut.reportPhishing(messageID: "",
                           messageBody: messageBody) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(apiServiceMock.requestStub.wasNotCalled)
    }

    func testReportPhishing_bodyIsNormal_apiIsCalled() {
        let expectation1 = expectation(description: "Closure is called")
        let messageBody = "Test body"
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains(ReportPhishing.defaultPath) {
                completion?(nil, ["Code": 1001], nil)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut.reportPhishing(messageID: "",
                           messageBody: messageBody) { error in
            XCTAssertNil(error)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }

    func testReportPhishing_apiReturnsError_receivedError() {
        let expectation1 = expectation(description: "Closure is called")
        let messageBody = "Test body"
        let stubbedError = NSError(domain: "error.com", code: 3, userInfo: [:])
        apiServiceMock.requestStub.bodyIs { _, _, path, _, _, _, _, _, _, completion in
            if path.contains(ReportPhishing.defaultPath) {
                completion?(nil, nil, stubbedError)
            } else {
                XCTFail("Unexpected path")
                completion?(nil, nil, nil)
            }
        }

        sut.reportPhishing(messageID: "",
                           messageBody: messageBody) { error in
            XCTAssertEqual(error, stubbedError)
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(apiServiceMock.requestStub.wasCalledExactlyOnce)
    }
}
