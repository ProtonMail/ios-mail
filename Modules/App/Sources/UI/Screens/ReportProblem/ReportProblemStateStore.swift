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

import Combine
import InboxCoreUI
import InboxCore
import SwiftUI

final class ReportProblemStateStore: ObservableObject, StateStore, @unchecked Sendable {
    @Published var state: ReportProblemState
    private let reportProblemService: ReportProblemService
    private let toastStateStore: ToastStateStore
    private let issueReportBuilder: IssueReportBuilder
    private let infoDictionary: [String: Any]?
    private let dismiss: () -> Void

    @MainActor
    init(
        state: ReportProblemState,
        reportProblemService: ReportProblemService,
        toastStateStore: ToastStateStore,
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary,
        deviceInfo: DeviceInfo = UIDevice.current,
        dismiss: @escaping () -> Void
    ) {

        self.state = state
        self.reportProblemService = reportProblemService
        self.toastStateStore = toastStateStore
        self.issueReportBuilder = .init(infoDictionary: infoDictionary, deviceInfo: deviceInfo)
        self.infoDictionary = infoDictionary
        self.dismiss = dismiss
    }

    @MainActor
    func handle(action: ReportProblemAction) async {
        switch action {
        case .textEntered(let keyPath, let text):
            state.summaryValidation = .ok
            state[keyPath: keyPath] = text
        case .sendLogsToggleSwitched(let isEnabled):
            withAnimation(.easeInOut(duration: 0.2)) {
                state.sendLogsEnabled = isEnabled
            } completion: { [weak self] in
                Task {
                    await self?.handle(action: .scrollTo(element: isEnabled ? nil : .bottomInfoText))
                }
            }
        case .scrollTo(let element):
            state.scrollTo = element
        case .submit:
            if state.summary.count <= 10 {
                state.summaryValidation = .summaryLessThen10Characters
                state.scrollTo = .topInfoText
            } else {
                state.isLoading = true
                do {
                    try await reportProblemService.send(report: issueReport)
                    await handle(action: .reportSend)
                } catch {
                    await handle(action: .reportFailedToSend)
                }
                state.isLoading = false
            }
        case .reportSend:
            toastStateStore.present(toast: .information(message: "Problem report sent"))
            dismiss()
        case .reportFailedToSend:
            toastStateStore.present(toast: .information(message: "Failure"))
        }
    }

    private var issueReport: IssueReport {
        issueReportBuilder.build(
            with: .init(
                summary: state.summary,
                stepsToReproduce: state.stepsToReproduce,
                expectedResults: state.expectedResults,
                actualResults: state.actualResults,
                includeLogs: state.sendLogsEnabled
            )
        )
    }
}

private extension FormMultilineTextInput.ValidationStatus {

    static var summaryLessThen10Characters: Self {
        .failure(L10n.ReportProblem.summaryValidationError)
    }

}

