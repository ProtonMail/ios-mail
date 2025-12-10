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
import InboxCore
import InboxCoreUI
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

final class ReportProblemStateStore: StateStore {
    @Published var state: ReportProblemState
    private let reportProblemService: ReportProblemService
    private let toastStateStore: ToastStateStore
    private let issueReportBuilder: IssueReportBuilder
    private let dismiss: () -> Void

    init(
        state: ReportProblemState,
        reportProblemService: ReportProblemService,
        toastStateStore: ToastStateStore,
        mainBundle: Bundle = Bundle.main,
        deviceInfo: BasicDeviceInfo = UIDevice.current,
        dismiss: @escaping () -> Void
    ) {
        self.state = state
        self.reportProblemService = reportProblemService
        self.toastStateStore = toastStateStore
        self.issueReportBuilder = .init(mainBundle: mainBundle, deviceInfo: deviceInfo)
        self.dismiss = dismiss
    }

    func handle(action: ReportProblemAction) async {
        switch action {
        case .textEntered:
            state = state.copy(\.summaryValidation, to: .ok)
        case .sendLogsToggleSwitched(let isEnabled):
            withAnimation(.easeInOut(duration: 0.2)) {
                state = state.copy(\.sendLogsEnabled, to: isEnabled)
            } completion: { [weak self] in
                Task {
                    await self?.handle(action: .scrollTo(element: isEnabled ? nil : .bottomInfoText))
                }
            }
        case .scrollTo(let element):
            state = state.copy(\.scrollTo, to: element)
        case .submit:
            if state.summary.count <= 10 {
                state =
                    state
                    .copy(\.summaryValidation, to: .summaryLessThen10Characters)
                    .copy(\.scrollTo, to: .topInfoText)
            } else {
                state = state.copy(\.isLoading, to: true)
                do {
                    try await reportProblemService.send(report: issueReport)
                    await handle(action: .reportResponse(.success(())))
                } catch {
                    await handle(action: .reportResponse(.failure(error)))
                }
            }
        case .reportResponse(let result):
            state = state.copy(\.isLoading, to: false)
            switch result {
            case .success:
                toastStateStore.present(toast: .information(message: L10n.ReportProblem.successToast.string))
                dismiss()
            case .failure(let failure):
                switch failure {
                case .other(.network):
                    toastStateStore.present(toast: .error(message: L10n.ReportProblem.offlineFailureToast.string))
                default:
                    toastStateStore.present(toast: .error(message: L10n.ReportProblem.failureToast.string))
                }
            }
        case .closeButtonTapped:
            if isFormEmpty {
                dismiss()
            } else {
                state = state.copy(
                    \.alert,
                    to: .reportBugDismissConfirmationAlert(action: { [weak self] action in
                        await self?.handle(action: .alertActionTapped(action))
                    }))
            }
        case .alertActionTapped(let action):
            state = state.copy(\.alert, to: nil)
            switch action {
            case .cancel:
                break
            case .close:
                dismiss()
            }
        }
    }

    private var isFormEmpty: Bool {
        [state.summary, state.actualResults, state.expectedResults, state.stepsToReproduce].allSatisfy(\.isEmpty)
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

private extension FormTextInput.ValidationStatus {
    static var summaryLessThen10Characters: Self {
        .failure(L10n.ReportProblem.summaryValidationError.string)
    }
}
