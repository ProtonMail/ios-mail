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
import ProtonCore_TestingToolkit

final class InAppFeedbackViewModelTests: XCTestCase {
    private var sut: InAppFeedbackViewModelProtocol!

    override func setUp() {
        super.setUp()
        sut = InAppFeedbackViewModel()
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
}
