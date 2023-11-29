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

import XCTest
@testable import ProtonMail
@testable import ProtonCoreDataModel

class ReferralProgramPromptPresenterTests: XCTestCase {
    private var mockFeatureFlagCache: MockFeatureFlagCache!
    private var mockFeatureFlagsService: MockFeatureFlagsDownloadServiceProtocol!
    private var mockNotificationCenter: NotificationCenter!

    private let mockUserID: UserID = "foo"

    override func setUp() {
        super.setUp()
        mockFeatureFlagsService = .init()
        mockNotificationCenter = NotificationCenter()

        mockFeatureFlagCache = MockFeatureFlagCache()
        mockFeatureFlagCache.featureFlagsStub.bodyIs { [unowned self] _, userID in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.referralPrompt.rawValue: userID == self.mockUserID])
        }
    }

    override func tearDown() {
        super.tearDown()
        mockFeatureFlagCache = nil
        mockFeatureFlagsService = nil
        mockNotificationCenter = nil
    }

    func testGivenNoDateIsSavedInTheStatus_WhenInitializingPresenterWithACustomDate_ThenTheDateShouldBeSaved() {
        // Test when initializing ReferralProgramPromptPresenter with a custom date
        // It should be saved when the firstRunDate in ReferralProgramPromptStatus is nil
        let expectedDate = Date()
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: true,
                                                         firstRunDate: nil)
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)

        _ = ReferralProgramPromptPresenter(userID: mockUserID,
                                           referralProgram: mockReferralProgram,
                                           featureFlagCache: mockFeatureFlagCache,
                                           referralProgramPromptStatus: mockStatus,
                                           featureFlagService: mockFeatureFlagsService,
                                           notificationCenter: mockNotificationCenter,
                                           firstRunDate: expectedDate)
        XCTAssertEqual(mockStatus.firstRunDate, expectedDate)
    }

    func testGivenADateIsSavedInTheStatus_WhenInitializingPresenterWithACustomDate_ThenTheDateShouldNotBeSaved() {
        // Test when initializing ReferralProgramPromptPresenter with a custom date
        // It should NOT be saved when the firstRunDate in ReferralProgramPromptStatus is not nil
        let savedRandomDate = Date().add(.day, value: -Int.random(in: 1...100))
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: true,
                                                         firstRunDate: savedRandomDate)
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)

        let otherRandomDate = Date().add(.day, value: Int.random(in: 1...100))!
        _ = ReferralProgramPromptPresenter(userID: mockUserID,
                                           referralProgram: mockReferralProgram,
                                           featureFlagCache: mockFeatureFlagCache,
                                           referralProgramPromptStatus: mockStatus,
                                           featureFlagService: mockFeatureFlagsService,
                                           notificationCenter: mockNotificationCenter,
                                           firstRunDate: otherRandomDate)
        XCTAssertEqual(mockStatus.firstRunDate, savedRandomDate)
    }

    func testGivenPromptShown_WhenCheckingToShowPrompt_ThenReturnsFalse() {
        // Test when referral program prompt was already shown
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: true,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }
    
    func testGivenReferralProgramNotEligible_WhenCheckingToShowPrompt_ThenReturnsFalse() {
        // Test when referral program is not eligible
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: false)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }
    
    func testGivenReferralPromptNotEnabledForUser_WhenCheckingToShowPrompt_ThenReturnsFalse() {
        // Test when referral prompt is not enabled for the user
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        mockFeatureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.referralPrompt.rawValue: false])
        }
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }
    
    func testGivenFirstRunDateLessThan30DaysAgo_WhenCheckingToShowPrompt_ThenReturnsFalse() {
        // Test when first run date is less than 30 days ago
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -29))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }
    
    func testGivenAllConditionsMet_WhenCheckingToShowPrompt_ThenReturnsTrue() {
        // Test when all conditions are met for showing referral program prompt
        // Expect: shouldShowReferralProgramPrompt() returns true
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertTrue(sut.shouldShowReferralProgramPrompt())
    }

    func testGivenThePromptIsNotShownWhenConditionsAreChecked_ThenUpdateFeatureFlagIsNotCalled() {
        // Test when all conditions are met for showing referral program prompt
        // Expect: shouldShowReferralProgramPrompt() returns true
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        _ = sut.shouldShowReferralProgramPrompt()
        XCTAssertTrue(mockFeatureFlagsService.updateFeatureFlagStub.wasNotCalled)
    }

    func testGivenTheConditonsAreMet_WhenThePromptIsShown_ThenUpdateFeatureFlagIsCalledExactlyOnce() {
        // Test when all conditions are met for showing referral program prompt
        // Expect: shouldShowReferralProgramPrompt() returns true
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        XCTAssertTrue(sut.shouldShowReferralProgramPrompt())
        sut.promptWasShown()
        XCTAssertTrue(mockFeatureFlagsService.updateFeatureFlagStub.wasCalledExactlyOnce)
    }

    func test_GivenOtherConditionsAreMet_WhenCallingDidShowMailboxOnce_ThenItShouldntPromptToPresent() {
        // Test when other conditions are met for showing referral program prompt
        // But we call didShowMailbox only once
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()

        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }

    func test_GivenAllConditionsAreMet_WhenGoingToBackground_ThenItShouldNotPromptToPresent() {
        // Test when all conditions are met for showing referral program prompt
        // But the app goes to the background
        // Expect: shouldShowReferralProgramPrompt() returns false
        let mockReferralProgram = ReferralProgram(link: "foo", eligible: true)
        let mockStatus = MockReferralProgramPromptStatus(referralProgramPromptWasShown: false,
                                                         firstRunDate: Date().add(.day, value: -31))
        let sut = ReferralProgramPromptPresenter(userID: mockUserID,
                                                 referralProgram: mockReferralProgram,
                                                 featureFlagCache: mockFeatureFlagCache,
                                                 referralProgramPromptStatus: mockStatus,
                                                 featureFlagService: mockFeatureFlagsService,
                                                 notificationCenter: mockNotificationCenter)
        sut.didShowMailbox()
        sut.didShowMailbox()
        sut.didShowMailbox()

        mockNotificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        XCTAssertFalse(sut.shouldShowReferralProgramPrompt())
    }
}

final class MockReferralProgramPromptStatus: ReferralProgramPromptStatus {
    private var _referralProgramPromptWasShown: Bool
    private var _firstRunDate: Date?

    init(referralProgramPromptWasShown: Bool, firstRunDate: Date?) {
        self._referralProgramPromptWasShown = referralProgramPromptWasShown
        self._firstRunDate = firstRunDate
    }
    
    var referralProgramPromptWasShown: Bool {
        get {
            _referralProgramPromptWasShown
        }
        set {
            _referralProgramPromptWasShown = newValue
        }
    }

    var firstRunDate: Date? {
        get {
            _firstRunDate
        }
        
        set {
            _firstRunDate = newValue
        }
    }
}
