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

class TaskCompletionHelperTests: XCTestCase {
    var sut: TaskCompletionHelper!

    override func setUp() {
        super.setUp()
        sut = TaskCompletionHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testCalculateIsInternetIssue_normalError() {
        let error = NSError.encryptionError()
        XCTAssertFalse(sut.calculateIsInternetIssue(error: error, currentNetworkStatus: .connectedViaCellular))
        XCTAssertFalse(sut.calculateIsInternetIssue(error: error, currentNetworkStatus: .connectedViaWiFi))
        XCTAssertFalse(sut.calculateIsInternetIssue(error: error, currentNetworkStatus: .connectedViaEthernet))

        XCTAssertTrue(sut.calculateIsInternetIssue(error: error, currentNetworkStatus: .notConnected))
    }

    func testCalculateIsInternetIssue_NSURLError() {
        let error1 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorTimedOut,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error1, currentNetworkStatus: .connectedViaCellular))

        let error2 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorCannotConnectToHost,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error2, currentNetworkStatus: .connectedViaCellular))

        let error3 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorCannotFindHost,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error3, currentNetworkStatus: .connectedViaCellular))

        let error4 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorDNSLookupFailed,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error4, currentNetworkStatus: .connectedViaCellular))

        let error5 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorNotConnectedToInternet,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error5, currentNetworkStatus: .connectedViaCellular))

        let error6 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorSecureConnectionFailed,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error6, currentNetworkStatus: .connectedViaCellular))

        let error7 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorDataNotAllowed,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error7, currentNetworkStatus: .connectedViaCellular))

        let error8 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorCannotFindHost,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error8, currentNetworkStatus: .connectedViaCellular))

        let error9 = NSError.CreateError(NSURLErrorDomain,
                                        code: NSURLErrorHTTPTooManyRedirects,
                                        localizedDescription: "Test",
                                        localizedFailureReason: "Test")
        XCTAssertFalse(sut.calculateIsInternetIssue(error: error9, currentNetworkStatus: .connectedViaCellular))
    }

    func testCalculateIsInternetIssue_withNSPOSIXError() {
        let error = NSError.CreateError(NSPOSIXErrorDomain,
                                       code: 100,
                                       localizedDescription: "", localizedFailureReason: "")
        XCTAssertTrue(sut.calculateIsInternetIssue(error: error, currentNetworkStatus: .connectedViaCellular))

        let error1 = NSError.CreateError(NSPOSIXErrorDomain,
                                       code: 1000,
                                       localizedDescription: "", localizedFailureReason: "")
        XCTAssertFalse(sut.calculateIsInternetIssue(error: error1, currentNetworkStatus: .connectedViaCellular))
    }

    func testHandleReachabilityChangedNotification_timeoutError() {
        expectation(forNotification: .reachabilityChanged, object: 0, handler: nil)
        sut.handleReachabilityChangedNotification(isTimeoutError: true, isInternetIssue: false)
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleReachabilityChangedNotification_internetIssue() {
        expectation(forNotification: .reachabilityChanged, object: 1, handler: nil)
        sut.handleReachabilityChangedNotification(isTimeoutError: false, isInternetIssue: true)
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testHandleReachabilityChangedNotification_bothError() {
        expectation(forNotification: .reachabilityChanged, object: 0, handler: nil)
        sut.handleReachabilityChangedNotification(isTimeoutError: true, isInternetIssue: true)
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testParseStatusCodeIfErrorReceivedFromNetworkResponse() {
        let testResponse = HTTPURLResponse(statusCode: 400)
        let testUserInfo = [TaskCompletionHelper.Constant.networkResponseErrorKey: testResponse]
        XCTAssertEqual(sut.parseStatusCodeIfErrorReceivedFromNetworkResponse(errorUserInfo: testUserInfo), 400)

        XCTAssertNil(sut.parseStatusCodeIfErrorReceivedFromNetworkResponse(errorUserInfo: [:]))
    }

    func testCalculateTaskResult_withInternetIssue() {
        var taskResult = QueueManager.TaskResult()
        XCTAssertEqual(taskResult.action, .none)
        sut.calculateTaskResult(result: &taskResult, isInternetIssue: true, statusCode: 200, errorCode: 0)
        XCTAssertEqual(taskResult.action, .connectionIssue)
    }

    func testCalculateTaskResult_withoutInternetIssue() {
        var taskResult = QueueManager.TaskResult()
        XCTAssertEqual(taskResult.action, .none)

        // status code == 404
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 404, errorCode: 0)
        XCTAssertEqual(taskResult.action, .removeRelated)

        // status code == 500 with 0 retry
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 500, errorCode: 0)
        XCTAssertEqual(taskResult.action, .retry)
        XCTAssertEqual(taskResult.retry, 1)

        // status code == 500 with 3 retries
        taskResult = QueueManager.TaskResult()
        taskResult.retry = 3
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 500, errorCode: 0)
        XCTAssertEqual(taskResult.action, .removeRelated)
        XCTAssertEqual(taskResult.retry, 3)

        // status code == 200 errorCode == 9001
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 200, errorCode: 9001)
        XCTAssertEqual(taskResult.action, .removeRelated)

        // status code == 200 errorCode > 1000
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 200, errorCode: 1001)
        XCTAssertEqual(taskResult.action, .removeRelated)

        // status code == 200 errorCode < 200
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 200, errorCode: 100)
        XCTAssertEqual(taskResult.action, .removeRelated)

        // status code != 200
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 400, errorCode: 0)
        XCTAssertEqual(taskResult.action, .removeRelated)

        // status code == 200 errorCode == 665
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 200, errorCode: 665)
        XCTAssertEqual(taskResult.action, .checkReadQueue)

        // status code == 200 errorCode != 665
        taskResult = QueueManager.TaskResult()
        sut.calculateTaskResult(result: &taskResult,
                                isInternetIssue: false,
                                statusCode: 200, errorCode: 600)
        XCTAssertEqual(taskResult.action, .removeRelated)
    }
}
