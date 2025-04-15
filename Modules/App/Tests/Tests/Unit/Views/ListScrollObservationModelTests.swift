// Copyright (c) 2024 Proton Technologies AG
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

final class ListScrollObservationModelTests: XCTestCase {

    private var onEventAtTopChangeCount: Int!
    private var onEventAtTopChangeValue: Bool!

    override func setUp() {
        super.setUp()
        onEventAtTopChangeCount = 0
        onEventAtTopChangeValue = nil
    }

    private func createSUT() -> ListScrollObservationModel {
        // Initially isAtTop is true
        return ListScrollObservationModel { [weak self] isAtTop in
            self?.onEventAtTopChangeCount += 1
            self?.onEventAtTopChangeValue = isAtTop
        }
    }

    @MainActor
    func test_listOffsetUpdate_whenDoesNotScrollBeyondThreshold_itDoesNotCallOnEventAtTopChange() {
        let sut = createSUT()

        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold - 35)
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold - 25)
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold - 5)

        XCTAssertEqual(onEventAtTopChangeCount, 0)
        XCTAssertNil(onEventAtTopChangeValue)
    }

    @MainActor
    func test_listOffsetUpdate_whenScrollsBeyondThresholdMultipleTimes_itCallsOnEventAtTopChangeWithFalseOnlyOnce() {
        let sut = createSUT()

        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold + 10)
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold + 20)
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold + 30)

        XCTAssertEqual(onEventAtTopChangeCount, 1)
        XCTAssertEqual(onEventAtTopChangeValue, false)
    }

    @MainActor
    func test_listOffsetUpdate_whenScrollsBeyondThresholdAndBack_itCallsForEachValueChange() {
        let sut = createSUT()

        // Initially isAtTop is true, move out of threshold
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold + 10)

        XCTAssertEqual(onEventAtTopChangeCount, 1)
        XCTAssertEqual(onEventAtTopChangeValue, false)

        // Move further out of threshold, callback should not be called again
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold + 20)

        XCTAssertEqual(onEventAtTopChangeCount, 1)  // Still 1, no change

        // Move back within threshold
        sut.listOffsetUpdate(verticalAdjustedContentInset: 0, oldOffsetY: 0, newOffsetY: sut.sensitivityThreshold - 10)

        XCTAssertEqual(onEventAtTopChangeCount, 2)
        XCTAssertEqual(onEventAtTopChangeValue, true)
    }
}
