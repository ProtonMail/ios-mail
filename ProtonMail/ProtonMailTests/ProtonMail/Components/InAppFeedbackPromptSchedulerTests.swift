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
    var storage: UserDefaults!
    var sut: InAppFeedbackPromptScheduler!
    let suiteId = String.randomString(32)
    
    override func setUp() {
        super.setUp()
        
        storage = UserDefaults.init(suiteName: suiteId)
    }
    
    override func tearDown() {
        super.tearDown()
        storage.removePersistentDomain(forName: suiteId)
        storage = nil
        sut = nil
    }
    
    func testShouldNotPromptWhenAFeedbackWasAlreadySubmitted() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            return false
        }, showPromptHandler: { _ in
            XCTFail("Should not have prompted")
        })
        storage.feedbackWasSubmitted = true
        // Simulate entering foreground enough times
        sut.markAsInForeground()
        sut.markAsInForeground()
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
    }
    
    func testShouldNotPromptWhenEnteringForegroundOnlyOnce() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            return false
        }, showPromptHandler: { _ in
            XCTFail("Should not have prompted")
        })
        // Simulate entering foreground just once
        sut.markAsInForeground()
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
    }
    
    func testShouldPromptWhenEnteringForegroundMoreThanOnce() {
        let expectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptDelayTime: 0.01,
                                           promptAllowedHandler: {
            expectation.fulfill()
            return false
        }, showPromptHandler: nil)
        // Simulate entering foreground enough times
        sut.markAsInForeground()
        sut.markAsInForeground()
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testShouldNotPromptAfterHavingPromptAlready() {
        let promptExpectation = self.expectation(description: "Should prompt expectation")
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptDelayTime: 0.01,
                                           promptAllowedHandler: {
            return true
        }, showPromptHandler: { _ in
            promptExpectation.fulfill()
        })
        // Simulate entering foreground enough times
        sut.markAsInForeground()
        sut.markAsInForeground()
        
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testThatCancelingScheduledPromptWorks() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptDelayTime: 0.1,
                                           promptAllowedHandler: {
            return true
        }, showPromptHandler: { _ in
            XCTFail("This should not get called")
        })
        // Simulate entering foreground enough times
        sut.markAsInForeground()
        sut.markAsInForeground()
        // Lets cancel the scheduling right away
        sut.cancelScheduledPrompt()
        XCTAssertNil(sut.timer)
        delay(0.15) {
            // Artifical waiting to make sure the fail is not triggered
        }
    }
    
    func testThatExternalValidationIsDoneAfterPromptDelayTime() {
        let expectation = expectation(description: "promptAllowedHandler should get called")
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptDelayTime: 0.05,
                                           promptAllowedHandler: {
            // This external validation will be called after delay time and should prevent the showPromptHandler call
            expectation.fulfill()
            return false
        }, showPromptHandler: { _ in
            XCTFail("This should not get called")
        })
        // Simulate entering foreground enough times
        sut.markAsInForeground()
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
        sut.markAsInForeground()
        // Timer was scheduled and this should fail:
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testThatPreconditionsAreChecked() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            XCTFail("This should not get called")
            return false
        }, showPromptHandler: { _ in
            XCTFail("This should not get called")
        })
        storage.numberOfForegroundEnteringRegistered = 2
        XCTAssertTrue(sut.areShowingPromptPreconditionsMet)
        storage.numberOfForegroundEnteringRegistered = 0
        
        storage.feedbackWasSubmitted = true
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
        
        storage.feedbackWasSubmitted = false
        storage.feedbackPromptWasShown = true
        XCTAssertFalse(sut.areShowingPromptPreconditionsMet)
    }
    
    func testThatMarkAsInForegroundIncreasesStorageCounter() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            XCTFail("This should not get called")
            return false
        }, showPromptHandler: { _ in
            XCTFail("This should not get called")
        })
        
        XCTAssertEqual(storage.numberOfForegroundEnteringRegistered, 0)
        sut.markAsInForeground()
        XCTAssertEqual(storage.numberOfForegroundEnteringRegistered, 1)
    }
    
    func testThatSchedulerModifiesStorageOnSubmit() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            return false
        }, showPromptHandler: { _ in
            XCTFail("Should not have prompted")
        })
        XCTAssertFalse(storage.feedbackPromptWasShown)
        XCTAssertFalse(storage.feedbackWasSubmitted)
        sut.markAsFeedbackSubmitted()
        XCTAssertTrue(storage.feedbackPromptWasShown)
        XCTAssertTrue(storage.feedbackWasSubmitted)
    }
    
    func testThatNumberOfForegroundCallsIsIncreasingAsExpected() {
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptAllowedHandler: {
            return false
        }, showPromptHandler: { _ in
            XCTFail("Should not have prompted")
        })
        XCTAssertEqual(storage.numberOfForegroundEnteringRegistered, 0)
        sut.markAsInForeground()
        XCTAssertEqual(storage.numberOfForegroundEnteringRegistered, 1)
    }
    
    func testThatCompletedHandlerIsHandled() {
        let expectationPromptAllowed = expectation(description: "Prompt check should be called")
        let expectationPromptHandler = expectation(description: "Prompt handler should be called")
        let expectationPostChecks = expectation(description: "Post checks should be called")
        let expectedFeedbackPromptWasShown = true
        let expectedFeedbackWasSubmitted = true
        let postCheckHandler = { [weak self] in
            expectationPostChecks.fulfill()
            
            XCTAssertEqual(self!.storage.feedbackPromptWasShown, expectedFeedbackPromptWasShown)
            XCTAssertEqual(self!.storage.feedbackWasSubmitted, expectedFeedbackWasSubmitted)
        }
        sut = InAppFeedbackPromptScheduler(storage: storage,
                                           promptDelayTime: 0.001,
                                           promptAllowedHandler: {
            expectationPromptAllowed.fulfill()
            return true
        }, showPromptHandler: { completedHandler in
            expectationPromptHandler.fulfill()
            completedHandler?(expectedFeedbackWasSubmitted)
            postCheckHandler()
        })
        sut.markAsInForeground()
        sut.markAsInForeground()
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
