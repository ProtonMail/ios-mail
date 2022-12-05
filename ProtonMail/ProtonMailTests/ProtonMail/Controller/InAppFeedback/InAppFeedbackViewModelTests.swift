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

final class InAppFeedbackViewModelTests: XCTestCase {
    private var sut: InAppFeedbackViewModel!

    override func setUp() {
        super.setUp()
        sut = InAppFeedbackViewModel(submissionHandler: { _ in
            // empty
        })
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testSelectedRatingIsInitiallyNil() {
        XCTAssertEqual(sut.selectedRating, nil)
    }

    func testViewModeIsInitiallyRatingOnly() {
        XCTAssertEqual(sut.viewMode, .ratingOnly)
    }

    func testUserCommentIsInitiallyNil() {
        XCTAssertEqual(sut.userComment, nil)
    }

    func testRatingScaleIsTheDefaultOne() {
        XCTAssertEqual(sut.ratingScale, Rating.defaultScale)
    }

    func testSelectingRatingSetsThePropertyToTheRightRating() {
        let rating = Rating.neutral
        sut.select(rating: rating)
        XCTAssertEqual(sut.selectedRating, rating)
    }

    func testChangingToAnyRatingSetsTheViewModeToFull() {
        sut.select(rating: .happy)
        XCTAssertEqual(sut.viewMode, .full)
    }


    func testUpdatingUserCommentSetsThePropertyRightfully() {
        let comment = "A random comment"
        sut.updateFeedbackComment(comment: comment)
        XCTAssertEqual(sut.userComment, comment)
    }

    func testSelectingRatingShouldChangeViewMode() {
        let previousViewMode = sut.viewMode
        sut.select(rating: .happy)
        let currentViewMode = sut.viewMode
        XCTAssertNotEqual(previousViewMode, currentViewMode)
    }

    func testChangingViewModeShouldCallUpdateViewCallbackClosure() {
        var callCounter = 0
        sut.updateViewCallback = {
            callCounter += 1
        }
        // We change the view mode by selecting a rating, proving first that it works with the test above
        sut.select(rating: .happy)
        XCTAssert(callCounter > 0)
    }
    
    func testThatRatingIsParsedCorrectly() {
        XCTAssertEqual(Rating.happy.intValue, 5)
        XCTAssertEqual(Rating.satisfied.intValue, 4)
        XCTAssertEqual(Rating.neutral.intValue, 3)
        XCTAssertEqual(Rating.dissatisfied.intValue, 2)
        XCTAssertEqual(Rating.unhappy.intValue, 1)
    }
    
    func testThatSubmitCallTriggersSubmissionHandler() {
        let expectation = expectation(description: "Submission handler should be called")
        let viewModel = InAppFeedbackViewModel { _ in
            expectation.fulfill()
        }
        viewModel.submitFeedback()
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testThatCancelCallTriggersSubmissionHandler() {
        let expectation = expectation(description: "Submission handler should be called")
        let viewModel = InAppFeedbackViewModel { _ in
            expectation.fulfill()
        }
        viewModel.cancelFeedback()
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testThatFeedbackIsTransformedCorrectly() {
        let expectedComment = "Happy"
        let expectedRating: Rating = .happy
        let result = InAppFeedbackViewModel.makeUserFeedback(type: "Feedback", rating: expectedRating, comment: expectedComment)
        switch result {
        case.failure(_):
            XCTFail("Unexpected behavior")
        case .success(let feedback):
            XCTAssertEqual(feedback.score, expectedRating.intValue)
            XCTAssertTrue(feedback.text == expectedComment)
        }
    }
    
    func testThatMakeFeedbackIsValidating() {
        let feedback0 = InAppFeedbackViewModel.makeUserFeedback(type: "Feedback", rating: nil, comment: "")
        let feedback1 = InAppFeedbackViewModel.makeUserFeedback(type: "", rating: Rating.happy, comment: "")
        [feedback0, feedback1].forEach { feedback in
            switch feedback {
            case .failure(let error):
                switch error {
                case .validation(let message):
                    XCTAssertFalse(message.isEmpty)
                default:
                    XCTFail("Validation error expected")
                }
            case .success(_):
                XCTFail("Unexpected behavior")
            }
        }
    }
}
