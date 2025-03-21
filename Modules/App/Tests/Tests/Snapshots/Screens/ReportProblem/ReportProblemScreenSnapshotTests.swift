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
import InboxCoreUI
import InboxSnapshotTesting
import InboxTesting
import XCTest

class ReportProblemScreenSnapshotTests: BaseTestCase {

    func testReportProblemScreenLayoutsCorrectly() {
        let sut = ReportProblemScreen(reportProblemService: ReportProblemServiceSpy())
            .environmentObject(ToastStateStore(initialState: .initial))
        assertSnapshotsOnIPhoneX(of: sut)
    }

    func testFormValidationStyle() {
        var state = ReportProblemState.initial
        state.summaryValidation = .failure("This field must be more than 10 characters.")
        let sut = ReportProblemScreen(state: state, reportProblemService: ReportProblemServiceSpy())
            .environmentObject(ToastStateStore(initialState: .initial))

        assertSnapshotsOnIPhoneX(of: sut)
    }

}
