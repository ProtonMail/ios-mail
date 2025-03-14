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

import Foundation
import Combine

class ReportProblemStateStore: ObservableObject, StateStore {
    @Published var state: ReportProblemState

    init(state: ReportProblemState) {
        self.state = state
    }

    func handle(action: ReportProblemAction) {
        switch action {
        case .textEntered(let keyPath, let text):
            state.summaryValidation = .ok
            state[keyPath: keyPath] = text
        case .sendLogsToggleSwitched(let isEnabled):
            state.sendLogsEnabled = isEnabled
            state.scrollTo = isEnabled ? nil : .bottomInfoText
        case .cleanUpScrollingState:
            state.scrollTo = nil
        case .submit:
            if state.summary.count <= 10 {
                state.summaryValidation = .summaryLessThen10Characters
                state.scrollTo = .topInfoText
            } else {
                state.isLoading = true

                // FIXME: - To remove
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                    self?.state.isLoading = false
                }
            }
        }
    }
}

private extension FormMultilineTextInput.ValidationStatus {

    static var summaryLessThen10Characters: Self {
        .failure(L10n.ReportProblem.summaryValidationError)
    }

}
