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
import ProtonCore_TestingToolkit

class FeatureFlagsDownloadServiceTests: XCTestCase {

    var apiServiceMock: APIServiceMock!
    var appRatingStatusProvider: MockAppRatingStatusProvider!
    var scheduleSendEnableStatusMock: MockScheduleSendEnableStatusProvider!
    var userIntroductionProgressProviderMock: MockUserIntroductionProgressProvider!
    var senderImageStatusProviderMock: MockSenderImageStatusProvider!
    var sut: FeatureFlagsDownloadService!
    var userID: UserID = UserID(rawValue: String.randomString(20))

    override func setUp() {
        super.setUp()
        apiServiceMock = APIServiceMock()
        appRatingStatusProvider = .init()
        scheduleSendEnableStatusMock = .init()
        userIntroductionProgressProviderMock = .init()
        senderImageStatusProviderMock = .init()
        sut = FeatureFlagsDownloadService(
            userID: userID,
            apiService: apiServiceMock,
            sessionID: "",
            appRatingStatusProvider: appRatingStatusProvider,
            scheduleSendEnableStatusProvider: scheduleSendEnableStatusMock,
            userIntroductionProgressProvider: userIntroductionProgressProviderMock,
            senderImageEnableStatusProvider: senderImageStatusProviderMock
        )
    }

    override func tearDown() {
        super.tearDown()
        apiServiceMock = nil
        appRatingStatusProvider = nil
        scheduleSendEnableStatusMock = nil
        userIntroductionProgressProviderMock = nil
        senderImageStatusProviderMock = nil
        sut = nil
    }

    func testRegisterNewSubscriber() {
        let mock = SubscriberMock()
        sut.register(newSubscriber: mock)

        XCTAssertEqual(sut.subscribers.count, 1)
    }

    func testGetFeatureFlag() throws {
        let subscriberMock = SubscriberMock()
        sut.register(newSubscriber: subscriberMock)

        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/core/v4/features") {
                let response = FeatureFlagTestData.data.parseObjectAny()!
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        let expectation1 = expectation(description: "Closure is called")
        sut.getFeatureFlags { result in
            switch result {
            case .failure:
                XCTFail("Should not get here")
            case .success(let response):
                XCTAssertFalse(response.result.isEmpty)
            }
            XCTAssertTrue(subscriberMock.isHandleNewFeatureFlagsCalled)
            XCTAssertFalse(subscriberMock.receivedFeatureFlags.isEmpty)

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertNotNil(sut.lastFetchingTime)
        XCTAssertTrue(scheduleSendEnableStatusMock.callSetScheduleSendStatus.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(scheduleSendEnableStatusMock.callSetScheduleSendStatus.lastArguments)
        XCTAssertTrue(argument.a1)
        XCTAssertEqual(argument.a2, userID)

        XCTAssertTrue(senderImageStatusProviderMock.setIsSenderImageEnableStub.wasCalledExactlyOnce)
        let argument2 = try XCTUnwrap(
            senderImageStatusProviderMock.setIsSenderImageEnableStub.lastArguments
        )
        XCTAssertTrue(argument2.a1)
        XCTAssertEqual(argument2.a2, userID)
    }

    func testFetchingFlagsIn5mins_receiveFetchingTooOften() {
        let date5minsBefore = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 - 300))
        sut.setLastFetchedTime(date: date5minsBefore)
        let expectation1 = expectation(description: "Closure called")
        sut.getFeatureFlags { result in
            switch result {
            case .success:
                XCTFail("Should not reach here")
            case .failure(let error):
                if case .fetchingTooOften = error {
                    break
                } else {
                    XCTFail("Should not reach here")
                }
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testWhenRemoteFlagIsChangedFromOffToOn_spotlightIsResetForCurrentUser() throws {
        userIntroductionProgressProviderMock.markSpotlight(for: .scheduledSend, asSeen: false, byUserWith: userID)

        apiServiceMock.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, completion in
            if path.contains("/core/v4/features") {
                let response = FeatureFlagTestData.data.parseObjectAny()!
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.badResponse()))
            }
        }

        let expectation1 = expectation(description: "Closure called")

        sut.getFeatureFlags { _ in
            expectation1.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(userIntroductionProgressProviderMock.markSpotlightStub.callCounter, 1)
        let lastCallArguments = try XCTUnwrap(userIntroductionProgressProviderMock.markSpotlightStub.lastArguments)
        XCTAssertEqual(lastCallArguments.first, .scheduledSend)
        XCTAssertEqual(lastCallArguments.second, false)
        XCTAssertEqual(lastCallArguments.third, userID)
    }
}

class SubscriberMock: FeatureFlagsSubscribeProtocol {
    var isHandleNewFeatureFlagsCalled = false
    var receivedFeatureFlags: [String: Any] = [:]

    func handleNewFeatureFlags(_ featureFlags: [String: Any]) {
        isHandleNewFeatureFlagsCalled = true
        receivedFeatureFlags = featureFlags
    }
}
