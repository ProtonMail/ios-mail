// Copyright (c) 2025 Proton Technologies AG
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

@testable import ProtonMail
import XCTest
import InboxTesting

class ReportProblemStateStoreTests: BaseTestCase {

    var sut: ReportProblemStateStore!

    override func setUp() {
        super.setUp()

        sut = ReportProblemStateStore(state: .initial)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    @MainActor
    func testFormSubmission_WhenSummaryHasLessThen10Characters_ItFailsValidation() {
        sut.handle(action: .textEntered(\.summary, text: "Hello"))
        sut.handle(action: .submit)

        XCTAssertEqual(sut.state.scrollTo, .topInfoText)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(sut.state.summaryValidation, .failure("This field must be more than 10 characters"))

        sut.handle(action: .cleanUpScrollingState)

        XCTAssertEqual(sut.state.scrollTo, nil)
    }

    @MainActor
    func testFormSubmission_WhenLogsToggleIsDisabled_WhenValidationSuccess_ItStartsLoading() {
        let fields: [(WritableKeyPath<ReportProblemState, String>, String)] = [
            (\.summary, "summary"),
            (\.expectedResults, "expected results"),
            (\.actualResults, "actual results"),
            (\.stepsToReproduce, "steps to reproduce")
        ]

        fields.forEach { field, text in
            sut.handle(action: .textEntered(field, text: "Hello \(text)!"))
        }

        XCTAssertEqual(sut.state.summary, "Hello summary!")
        XCTAssertEqual(sut.state.expectedResults, "Hello expected results!")
        XCTAssertEqual(sut.state.actualResults, "Hello actual results!")
        XCTAssertEqual(sut.state.stepsToReproduce, "Hello steps to reproduce!")

        sut.handle(action: .sendLogsToggleSwitched(isEnabled: false))
        XCTAssertEqual(sut.state.scrollTo, .bottomInfoText)
        sut.handle(action: .cleanUpScrollingState)

        sut.handle(action: .submit)

        XCTAssertEqual(sut.state.isLoading, true)
    }

}
