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
import InboxTesting
import InboxCoreUI
import proton_app_uniffi
import Testing

final class ReportProblemStateStoreTests {
    var sut: ReportProblemStateStore!
    var toastStateStore: ToastStateStore!
    var dismissInvokeCount: Int!
    private var reportProblemServiceSpy: ReportProblemServiceSpy!

    init() async {
        reportProblemServiceSpy = .init()
        toastStateStore = .init(initialState: .initial)
        dismissInvokeCount = 0
        sut = await ReportProblemStateStore(
            state: .initial,
            reportProblemService: reportProblemServiceSpy,
            toastStateStore: toastStateStore,
            mainBundle: BundleStub(infoDictionary: [
                "CFBundleVersion": "127",
                "CFBundleShortVersionString": "0.2.0",
            ]),
            deviceInfo: DeviceInfoStub(),
            dismiss: { self.dismissInvokeCount += 1 }
        )
    }

    deinit {
        reportProblemServiceSpy = nil
        toastStateStore = nil
        dismissInvokeCount = nil
        sut = nil
    }

    @Test
    func formSubmission_WhenSummaryHasLessThen10Characters_ItFailsValidation() async {
        sut.state = sut.state.copy(\.summary, to: "Hello")
        await sut.handle(action: .textEntered)
        await sut.handle(action: .submit)

        #expect(sut.state.scrollTo == .topInfoText)
        #expect(sut.state.isLoading == false)
        #expect(sut.state.summaryValidation == .failure("This field must be more than 10 characters"))

        await sut.handle(action: .scrollTo(element: nil))

        #expect(sut.state.scrollTo == nil)
    }

    @Test
    func formSubmission_WhenLogsToggleIsDisabled_WhenValidationSuccess_ItSendsRequestWithSuccess() async {
        let fields: [(WritableKeyPath<ReportProblemState, String>, String)] = [
            (\.summary, "summary"),
            (\.expectedResults, "expected results"),
            (\.actualResults, "actual results"),
            (\.stepsToReproduce, "steps to reproduce")
        ]

        await fields.asyncForEach { field, text in
            sut.state = sut.state.copy(field, to: "Hello \(text)!")
            await sut.handle(action: .textEntered)
        }

        #expect(sut.state.summary == "Hello summary!")
        #expect(sut.state.expectedResults == "Hello expected results!")
        #expect(sut.state.actualResults == "Hello actual results!")
        #expect(sut.state.stepsToReproduce == "Hello steps to reproduce!")

        await sut.handle(action: .sendLogsToggleSwitched(isEnabled: false))

        #expect(sut.state.sendLogsEnabled == false)

        await sut.handle(action: .submit)
        #expect(sut.state.isLoading == false)
        #expect(reportProblemServiceSpy.invokedSendWithReport == [
            .init(
                operatingSystem: "iOS - iPhone",
                operatingSystemVersion: "18.4",
                client: "iOS_Native",
                clientVersion: "7.0.0 (127)",
                clientType: .email,
                title: "Proton Mail App bug report",
                summary: "Hello summary!",
                stepsToReproduce: "Hello steps to reproduce!",
                expectedResult: "Hello expected results!",
                actualResult: "Hello actual results!",
                logs: false
            )
        ])
        #expect(toastStateStore.state.toasts == [.information(message: L10n.ReportProblem.successToast.string)])
        #expect(dismissInvokeCount == 1)
    }

    @Test
    func formSubmission_WhenValidationSuccess_ItSendsRequestWithFailureAndPresentsToast() async {
        reportProblemServiceSpy.error = .other(.sessionExpired)

        sut.state = sut.state.copy(\.summary, to: "Hello world!")
        await sut.handle(action: .textEntered)
        await sut.handle(action: .submit)
        #expect(reportProblemServiceSpy.invokedSendWithReport.count == 1)
        #expect(toastStateStore.state.toasts == [.error(message: L10n.ReportProblem.failureToast.string)])
        #expect(dismissInvokeCount == 0)
    }

    @Test
    func formSubmission_WhenDeviceIsOffline_ItPresentsToast() async {
        reportProblemServiceSpy.error = .other(.network)

        sut.state = sut.state.copy(\.summary, to: "Hello world!")
        await sut.handle(action: .textEntered)
        await sut.handle(action: .submit)
        #expect(reportProblemServiceSpy.invokedSendWithReport.count == 1)
        #expect(toastStateStore.state.toasts == [.error(message: L10n.ReportProblem.offlineFailureToast.string)])
        #expect(dismissInvokeCount == 0)
    }

    @Test
    func formDismiss_WhenFormIsEmpty_ItDismissesTheScreenWithoutConfrimationAlert() async {
        await sut.handle(action: .closeButtonTapped)

        #expect(dismissInvokeCount == 1)
        #expect(sut.state.alert == nil)
    }

    @Test
    func formDismiss_WhenFormIsNotEmpty_WhenConfrimationAlertIsPresented_WhenCancelIsTapped_ItDoesNotDismissScreen() async {
        sut.state = sut.state.copy(\.summary, to: "Hello world!")
        await sut.handle(action: .textEntered)

        await sut.handle(action: .closeButtonTapped)

        #expect(dismissInvokeCount == 0)
        #expect(sut.state.alert == .reportBugDismissConfirmationAlert(action: { _ in }))

        await sut.handle(action: .alertActionTapped(.cancel))

        #expect(dismissInvokeCount == 0)
        #expect(sut.state.alert == nil)
    }

    @Test
    func formDismiss_WhenFormIsNotEmpty_WhenConfrimationAlertIsPresented_WhenCloseIsTapped_ItDismissesScreen() async {
        sut.state = sut.state.copy(\.expectedResults, to: "Hello world!")
        await sut.handle(action: .textEntered)

        await sut.handle(action: .closeButtonTapped)

        #expect(dismissInvokeCount == 0)
        #expect(sut.state.alert == .reportBugDismissConfirmationAlert(action: { _ in }))

        await sut.handle(action: .alertActionTapped(.close))

        #expect(dismissInvokeCount == 1)
        #expect(sut.state.alert == nil)
    }
}

private extension Sequence {
    func asyncForEach(_ body: (Element) async -> Void) async {
        for element in self {
            await body(element)
        }
    }
}

private struct DeviceInfoStub: DeviceInfo {
    let model = "iPhone"
    let systemName = "iOS"
    let systemVersion = "18.4"
}
