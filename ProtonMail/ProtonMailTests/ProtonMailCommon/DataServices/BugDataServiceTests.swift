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
import ProtonCore_Services
import ProtonCore_Networking
@testable import ProtonMail

final class BugDataServiceTests: XCTestCase {
    private var service: BugDataService!
    private var apiService: APIServiceSpy!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.apiService = APIServiceSpy()
        self.service = BugDataService(api: self.apiService)
    }

    func testReportBugSucceeds() {
        let bug = "This is a bug message"
        let userName = "Robot"
        let email = "abc@pm.me"
        let lastReceivedPush = String(Date().timeIntervalSince1970)
        let reachability = "WiFi"
        let completionExpectations = expectation(description: "Wait async operation")
        self.service.reportBug(bug,
                               username: userName,
                               email: email,
                               lastReceivedPush: lastReceivedPush,
                               reachabilityStatus: reachability) { [weak self] error in
            guard let self = self else {
                XCTAssert(false, "Self is nil")
                return
            }
            guard let path = self.apiService.invokedRequestWithPath.first else {
                XCTAssert(false, "The invoked paths is empty")
                return
            }
            XCTAssertEqual(path, BugReportRequest.defaultPath, "The request path is wrong")
            guard let method = self.apiService.invokedRequestWithMethod.first else {
                XCTAssert(false, "The invoked method is empty")
                return
            }
            XCTAssertEqual(method, BugReportRequest.defaultMethod)
            guard let parameters = self.apiService.invokedRequestWithParameters.first as? [String: Any] else {
                XCTAssert(false, "The invoked parameter is empty")
                return
            }
            let expectedDescription = bug.appending("\nLP Timestamp:\(lastReceivedPush)").appending("\nReachability:\(reachability)")
            XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.description.rawValue] as! String, expectedDescription)
            XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.userName.rawValue] as! String, userName)
            XCTAssertEqual(parameters[BugReportRequest.ParameterKeys.email.rawValue] as! String, email)
            completionExpectations.fulfill()
        }

        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let jsonWithErrorCode: [String: Any] = [:]
        self.apiService.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, nil)
        wait(for: [completionExpectations], timeout: 5.0)
    }

    func testReportBugFailed() {
        let bug = "This is a bug message"
        let userName = "Robot"
        let email = "abc@pm.me"
        let lastReceivedPush = String(Date().timeIntervalSince1970)
        let reachability = "WiFi"
        let stubbedError = NSError(domain: "error.com", code: 1, userInfo: [:])

        let completionExpectations = expectation(description: "Wait async operation")
        self.service.reportBug(bug,
                               username: userName,
                               email: email,
                               lastReceivedPush: lastReceivedPush,
                               reachabilityStatus: reachability) { error in
            XCTAssertNotNil(error)
            completionExpectations.fulfill()
        }
        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let jsonWithErrorCode: [String: Any] = [:]
        self.apiService.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, stubbedError)
        wait(for: [completionExpectations], timeout: 5.0)
    }

    func testReportPhishingSucceeds() {
        let messageID = "message id"
        let body = "I am body"

        let completionExpectations = expectation(description: "Wait async operation")
        self.service.reportPhishing(messageID: messageID, messageBody: body) { [weak self] error in
            guard let self = self else {
                XCTAssert(false, "Self is nil")
                return
            }

            XCTAssertNil(error)

            guard let path = self.apiService.invokedRequestWithPath.first else {
                XCTAssert(false, "The invoked paths is empty")
                return
            }
            XCTAssertEqual(path, ReportPhishing.defaultPath, "The request path is wrong")
            guard let method = self.apiService.invokedRequestWithMethod.first else {
                XCTAssert(false, "The invoked method is empty")
                return
            }
            XCTAssertEqual(method, ReportPhishing.defaultMethod)
            guard let parameters = self.apiService.invokedRequestWithParameters.first as? [String: Any] else {
                XCTAssert(false, "The invoked parameter is empty")
                return
            }
            XCTAssertEqual(parameters[ReportPhishing.ParameterKeys.messageID.rawValue] as! String, messageID)
            XCTAssertEqual(parameters[ReportPhishing.ParameterKeys.body.rawValue] as! String, body)
            completionExpectations.fulfill()
        }
        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let jsonWithErrorCode: [String: Any] = [:]
        self.apiService.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, nil)
        wait(for: [completionExpectations], timeout: 5.0)
    }

    func testReportPhishingFailed() {
        let messageID = "message id"
        let body = "I am body"
        let stubbedError = NSError(domain: "error.com", code: 3, userInfo: [:])

        let completionExpectations = expectation(description: "Wait async operation")
        self.service.reportPhishing(messageID: messageID, messageBody: body) { error in
            XCTAssertEqual(error?.code ?? -1, stubbedError.code)
            completionExpectations.fulfill()
        }
        let urlSessionDataTaskStub = URLSessionDataTaskStub()
        let jsonWithErrorCode: [String: Any] = [:]
        self.apiService.invokedRequestWithCompletion.first??(urlSessionDataTaskStub, jsonWithErrorCode, stubbedError)
        wait(for: [completionExpectations], timeout: 5.0)
    }
}
