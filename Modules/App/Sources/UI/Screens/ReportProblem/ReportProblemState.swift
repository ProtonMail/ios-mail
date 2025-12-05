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

import InboxCore
import InboxCoreUI
import ProtonUIFoundations

struct ReportProblemState: Copying {
    var summary: String
    var expectedResults: String
    var stepsToReproduce: String
    var actualResults: String
    var sendLogsEnabled: Bool
    var scrollTo: ReportProblemScrollToElements?
    var summaryValidation: FormTextInput.ValidationStatus
    var isLoading: Bool
    var alert: AlertModel?
}

extension ReportProblemState {
    static var initial: Self {
        .init(
            summary: .empty,
            expectedResults: .empty,
            stepsToReproduce: .empty,
            actualResults: .empty,
            sendLogsEnabled: true,
            scrollTo: nil,
            summaryValidation: .ok,
            isLoading: false,
            alert: nil
        )
    }
}
