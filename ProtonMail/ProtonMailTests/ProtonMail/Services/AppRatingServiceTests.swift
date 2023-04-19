// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
@testable import ProtonMail
import ProtonCore_TestingToolkit
import XCTest

final class AppRatingServiceTests: XCTestCase {
    private var sut: AppRatingService!
    private var mockInternetStatus: MockInternetConnectionStatusProviderProtocol!
    private var mockAppRatingStatusProvider: MockAppRatingStatusProvider!
    private var mockFeatureFlagsService: MockFeatureFlagsDownloadServiceProtocol!
    private var mockAppRatingWrapper: MockAppRatingWrapper!
    private var mockNotificationCenter: NotificationCenter!
    private let timeout = 2.0

    override func setUp() {
        mockInternetStatus = .init()
        mockAppRatingStatusProvider = .init()
        mockFeatureFlagsService = .init()
        mockAppRatingWrapper = .init()
        mockNotificationCenter = NotificationCenter()

        let dependencies = AppRatingService.Dependencies(
            featureFlagService: mockFeatureFlagsService,
            appRating: mockAppRatingWrapper,
            internetStatus: mockInternetStatus,
            appRatingPrompt: mockAppRatingStatusProvider,
            notificationCenter: mockNotificationCenter
        )
        sut = AppRatingService(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockInternetStatus = nil
        mockAppRatingStatusProvider = nil
        mockFeatureFlagsService = nil
        mockAppRatingWrapper = nil
        mockNotificationCenter = nil
        sut = nil
    }

    func testPreconditionEventDidOccur_whenConditionsAreMet_andNavigatesToInboxTwice_itPromptsAppRating() {
        setUpSuccessConditions()

        recordPreconditionInBoxEvents(in: sut, times: 2)

        let expectation = expectation(description: "requestAppRating is called in the main thread")
        DispatchQueue.main.async {
            XCTAssertTrue(self.mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMet_andNavigatesToInboxTwice_featureStateIsUpdated() {
        setUpSuccessConditions()

        recordPreconditionInBoxEvents(in: sut, times: 2)

        XCTAssertTrue(mockAppRatingStatusProvider.setIsAppRatingEnabledStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockAppRatingStatusProvider.setAppRatingAsShownInCurrentVersionStub.wasCalledExactlyOnce)
        XCTAssertTrue(mockFeatureFlagsService.updateFeatureFlagStub.wasCalledExactlyOnce)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMet_andUserSignsInAndNavigatesToInbox4Times_itPromptsAppRating() {
        setUpSuccessConditions()

        sut.preconditionEventDidOccur(.userSignIn)
        recordPreconditionInBoxEvents(in: sut, times: 4)

        let expectation = expectation(description: "requestAppRating is called in the main thread")
        DispatchQueue.main.async {
            XCTAssertTrue(self.mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMet_andUserSignsInAndNavigatesToInboxTwice_itDoesNotPromptAppRating() {
        setUpSuccessConditions()

        sut.preconditionEventDidOccur(.userSignIn)
        recordPreconditionInBoxEvents(in: sut, times: 2)

        let expectation = expectation(description: "requestAppRating is called in the main thread")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        XCTAssertFalse(mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMet_andAppGoesInctive_itResetsInboxEventCounting() {
        setUpSuccessConditions()

        recordPreconditionInBoxEvents(in: sut, times: 1)
        mockNotificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        recordPreconditionInBoxEvents(in: sut, times: 1)

        let expect1 = expectation(description: "requestAppRating is not called because app went inactive")
        DispatchQueue.main.async {
            XCTAssertTrue(self.mockAppRatingWrapper.requestAppRatingStub.wasNotCalled)
            expect1.fulfill()
        }
        wait(for: [expect1], timeout: timeout)

        recordPreconditionInBoxEvents(in: sut, times: 1)

        let expect2 = expectation(description: "requestAppRating is not called because app went inactive")
        DispatchQueue.main.async {
            XCTAssertTrue(self.mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
            expect2.fulfill()
        }
        wait(for: [expect2], timeout: timeout)
    }

    func testPreconditionEventDidOccur_whenOnlyNavigatesToInboxOnce_itDoesNotPromptAppRating() {
        setUpSuccessConditions()

        recordPreconditionInBoxEvents(in: sut, times: 1)

        let expectation = expectation(description: "requestAppRating is not called")
        DispatchQueue.main.async {
            XCTAssertTrue(self.mockAppRatingWrapper.requestAppRatingStub.wasNotCalled)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
    }

    func testPreconditionEventDidOccur_whenOnlyNavigatesToInboxOnce_featureStateIsNotUpdated() {
        setUpSuccessConditions()

        recordPreconditionInBoxEvents(in: sut, times: 1)

        XCTAssertTrue(mockAppRatingStatusProvider.setIsAppRatingEnabledStub.wasNotCalled)
        XCTAssertTrue(mockAppRatingStatusProvider.setAppRatingAsShownInCurrentVersionStub.wasNotCalled)
        XCTAssertTrue(mockFeatureFlagsService.updateFeatureFlagStub.wasNotCalled)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMetExceptInternetConnection_itDoesNotPromptAppRating() {
        setUpSuccessConditions()
        mockInternetStatus.currentStatusStub.fixture = .notConnected

        recordPreconditionInBoxEvents(in: sut, times: 2)

        let expectation = expectation(description: "wait to check whther requestAppRating is called or not")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        XCTAssertFalse(mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMetExceptFeatureFlag_itDoesNotPromptAppRating() {
        setUpSuccessConditions()
        mockAppRatingStatusProvider.isAppRatingEnabledStub.bodyIs { _ in false }

        recordPreconditionInBoxEvents(in: sut, times: 2)

        let expectation = expectation(description: "wait to check whther requestAppRating is called or not")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        XCTAssertFalse(mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
    }

    func testPreconditionEventDidOccur_whenConditionsAreMetButPromptShownInCurrentVersion_itDoesNotPromptAppRating() {
        setUpSuccessConditions()
        mockAppRatingStatusProvider.hasAppRatingBeenShownInCurrentVersionStub.bodyIs { _ in true }

        recordPreconditionInBoxEvents(in: sut, times: 2)

        let expectation = expectation(description: "wait to check whther requestAppRating is called or not")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        XCTAssertFalse(mockAppRatingWrapper.requestAppRatingStub.wasCalledExactlyOnce)
    }
}

extension AppRatingServiceTests {

    private func setUpSuccessConditions() {
        mockInternetStatus.currentStatusStub.fixture = .connected
        mockAppRatingStatusProvider.isAppRatingEnabledStub.bodyIs { _ in true }
        mockAppRatingStatusProvider.hasAppRatingBeenShownInCurrentVersionStub.bodyIs { _ in false }
    }

    private func recordPreconditionInBoxEvents(in appRatingService: AppRatingService, times: Int) {
        for _ in 0..<times {
            appRatingService.preconditionEventDidOccur(.inboxNavigation)
        }
    }
}
