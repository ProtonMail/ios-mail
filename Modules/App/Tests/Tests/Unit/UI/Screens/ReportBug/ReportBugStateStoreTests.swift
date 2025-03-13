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

class ReportBugStateStoreTests: BaseTestCase {

    var sut: ReportBugStateStore!

    override func setUp() {
        super.setUp()

        sut = ReportBugStateStore(state: .initial)
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testFormSubmission_WhenSummaryHasLessThen10Characters_ItFailsValidation() {
        sut.handle(action: .textEntered(\.summary, text: "Hello"))
        sut.handle(action: .submit)

        XCTAssertEqual(sut.state.scrollTo, .topInfoText)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(sut.state.summaryValidation, .failure("This field must be more than 10 characters"))

        sut.handle(action: .cleanUpScrollingState)

        XCTAssertEqual(sut.state.scrollTo, nil)
    }

    func testFormSubmission_WhenLogsToggleIsDisabled_WhenValidationSuccess_ItStartsLoading() {
        let fields: [WritableKeyPath<ReportBugViewState, String>] = [
            \.summary,
            \.expectedResults,
            \.actualResults,
            \.stepsToReproduce
        ]

        fields.forEach { field in
            sut.handle(action: .textEntered(field, text: "Hello world!"))
        }

        fields.forEach { field in
            XCTAssertEqual(sut.state[keyPath: field], "Hello world!")
        }

        sut.handle(action: .sendLogsToggleSwitched(isEnabled: false))
        XCTAssertEqual(sut.state.scrollTo, .bottomInfoText)
        sut.handle(action: .cleanUpScrollingState)

        sut.handle(action: .submit)

        XCTAssertEqual(sut.state.isLoading, true)
    }

}
