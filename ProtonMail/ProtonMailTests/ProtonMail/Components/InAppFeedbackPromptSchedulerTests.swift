// Copyright (c) 2021 Proton Technologies AG
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

final class InAppFeedbackPromptSchedulerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var sut: InAppFeedbackPromptScheduler!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults.init(suiteName: #fileID)
    }
    override func tearDown() {
        super.tearDown()
        userDefaults.removePersistentDomain(forName: #fileID)
        userDefaults = nil
        sut = nil
    }
    
    func testShouldNotPromptWhenAFeedbackWasAlreadySubmitted() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            XCTFail("Should not have prompted")
            return false
        })
        sut.setFeedbackWasSubmitted()
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()
        let expectation = self.expectation(description: "Should not prompt expectation")
        delay(1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testShouldNotPromptWhenEnteringForegroundOnlyOnce() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            XCTFail("Should not have prompted")
            return false
        })
        // Simulate entering foreground just once
        sut.didEnterForeground()
        let expectation = self.expectation(description: "Should not prompt expectation")
        delay(1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testShouldPromptWhenEnteringForegroundMoreThanOnce() {
        let expectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            expectation.fulfill()
            return false
        })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testShouldNotPromptAfterHavingPromptAlready() {
        let promptExpectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            promptExpectation.fulfill()
            return true
        })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()
        
        // Simulate re-entering foreground another time
        let shouldNotPromptExpectation = self.expectation(description: "Should not prompt expectation")
        delay(2.0) {
            self.sut = InAppFeedbackPromptScheduler(storage: self.userDefaults,
                                                    onPrompt: {
                XCTFail("Should not have prompted")
                return false
            })
            self.sut.didEnterForeground()
        }
        delay(4.0) {
            shouldNotPromptExpectation.fulfill()
        }
        wait(for: [promptExpectation, shouldNotPromptExpectation], timeout: 5.0)
    }
    
    func testShouldNotPromptAgainWhenClosureReturnsTrue() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            true
        })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()
        
        // Simulate re-entering foreground another time
        let shouldNotPromptExpectation = self.expectation(description: "Should not prompt expectation")
        delay(2.0) {
            self.sut = InAppFeedbackPromptScheduler(storage: self.userDefaults,
                                                    onPrompt: {
                XCTFail("Should not have prompted")
                return false
            })
            self.sut.didEnterForeground()
        }
        delay(4.0) {
            shouldNotPromptExpectation.fulfill()
        }
        wait(for: [shouldNotPromptExpectation], timeout: 5.0)
    }
    
    func testShouldPromptAgainWhenClosureReturnsFalse() {
        let promptExpectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            promptExpectation.fulfill()
            return false
        })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()
        
        // Simulate re-entering foreground another time
        let shouldPromptAgainExpectation = self.expectation(description: "Should not prompt expectation")
        delay(2.0) {
            self.sut = InAppFeedbackPromptScheduler(storage: self.userDefaults,
                                                    onPrompt: {
                shouldPromptAgainExpectation.fulfill()
                return false
            })
            self.sut.didEnterForeground()
        }
        wait(for: [promptExpectation, shouldPromptAgainExpectation], timeout: 5.0)
    }

    func testFeedbackWasSubmittedIsSetToTrueWhenSubmittedFeedback() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: nil)
        sut.setFeedbackWasSubmitted()
        XCTAssertTrue(sut.feedbackWasSubmitted)
    }

    func testFeedbackPromptWasShownIsSetToTrueWhenPromptWasShownAndReturnedTrue() {
        let delayExpectation = self.expectation(description: "Delay expectation")
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: { true })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()

        delay(1.5) {
            self.sut = InAppFeedbackPromptScheduler(storage: self.userDefaults,
                                               onPrompt: nil)
            XCTAssertTrue(self.sut.feedbackPromptWasShown)
            delayExpectation.fulfill()
        }
        wait(for: [delayExpectation], timeout: 5.0)
    }

    func testNumberOfForegroundEnteringRegisteredIsIncrementedWhenCallingDidEnterForeground() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: nil)
        sut.setFeedbackWasSubmitted()
        XCTAssertEqual(sut.numberOfForegroundEnteringRegistered, 0)
        sut.didEnterForeground()
        XCTAssertEqual(sut.numberOfForegroundEnteringRegistered, 1)
        sut.didEnterForeground()
        XCTAssertEqual(sut.numberOfForegroundEnteringRegistered, 2)
    }

    func testShouldShowFeedbackPromptReturnsFalseWhenFeedbackSubmitted() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: nil)
        sut.setFeedbackWasSubmitted()
        XCTAssertFalse(sut.shouldShowFeedbackPrompt)
    }

    func testShouldShowFeedbackPromptReturnsFalseWhenFeedbackPromptWasShown() {
        let promptExpectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: {
            promptExpectation.fulfill()
            return true
        })
        // Simulate entering foreground enough times
        sut.didEnterForeground()
        sut.didEnterForeground()

        delay(1.5) { [sut] in
            XCTAssertFalse(sut!.shouldShowFeedbackPrompt)
        }
        wait(for: [promptExpectation], timeout: 5.0)
    }

    func testShouldShowFeedbackPromptReturnsFalseWhenNumberOfForegroundEnteringIsLowerOrEqualToNumberOfTimesToIgnore() {
        sut = InAppFeedbackPromptScheduler(storage: userDefaults,
                                           onPrompt: nil)
        // Simulate entering foreground not enough times
        sut.didEnterForeground()

        XCTAssertFalse(sut.shouldShowFeedbackPrompt)
    }

    func testShouldRestoreFeedbackWasSubmittedValueOnInit() {
        let storageMock = InAppFeedbackStorageMock()
        storageMock.feedbackWasSubmitted = Bool.random()
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: nil)
        XCTAssertEqual(storageMock.feedbackWasSubmitted, sut.feedbackWasSubmitted)
    }

    func testShouldSaveFeedbackWasSubmittedWhenSet() {
        let storageMock = InAppFeedbackStorageMock()
        let expectation = self.expectation(description: "FeedbackWasSubmitted Set")
        storageMock.onFeedbackWasSubmittedSet = {
            expectation.fulfill()
        }
        // Set value
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: nil)
        sut.setFeedbackWasSubmitted()
        wait(for: [expectation], timeout: 0.1)
    }

    func testShouldRestoreFeedbackWasShownValueOnInit() {
        let storageMock = InAppFeedbackStorageMock()
        storageMock.feedbackPromptWasShown = Bool.random()
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: nil)
        XCTAssertEqual(storageMock.feedbackPromptWasShown, sut.feedbackPromptWasShown)
    }

    func testShouldSaveFeedbackWasShownWhenSet() {
        let storageMock = InAppFeedbackStorageMock()
        let expectation = self.expectation(description: "FeedbackWasShown Set")
        storageMock.onFeedbackPromptWasShownSet = {
            expectation.fulfill()
        }
        // Set value
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: { true })
        sut.didEnterForeground()
        sut.didEnterForeground()
        wait(for: [expectation], timeout: 1.5)
    }

    func testShouldRestoreNumberOfForegroundEnteringRegisteredValueOnInit() {
        let storageMock = InAppFeedbackStorageMock()
        storageMock.numberOfForegroundEnteringRegistered = Int.random(in: 0..<100)
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: nil)
        XCTAssertEqual(storageMock.numberOfForegroundEnteringRegistered, sut.numberOfForegroundEnteringRegistered)

    }

    func testShouldSaveNumberOfForegroundEnteringRegisteredWhenSet() {
        let storageMock = InAppFeedbackStorageMock()
        let expectation = self.expectation(description: "NumberOfForegroundEnteringRegistered Set")
        storageMock.onNumberOfForegroundEnteringRegisteredSet = {
            expectation.fulfill()
        }
        // Set value
        sut = InAppFeedbackPromptScheduler(storage: storageMock, onPrompt: nil)
        sut.didEnterForeground()
        wait(for: [expectation], timeout: 0.1)
    }
}
