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
import proton_app_uniffi
import InboxCoreUI

class ReportProblemStateStoreTests: BaseTestCase {
    var sut: ReportProblemStateStore!
    var toastStateStore: ToastStateStore!
    var dismissInvokeCount: Int!
    private var reportProblemServiceSpy: ReportProblemServiceSpy!

    override func setUp() async throws {
        try await super.setUp()

        reportProblemServiceSpy = .init()
        toastStateStore = .init(initialState: .initial)
        dismissInvokeCount = 0
        sut = await ReportProblemStateStore(
            state: .initial,
            reportProblemService: reportProblemServiceSpy,
            toastStateStore: toastStateStore,
            infoDictionary: [
                "CFBundleVersion": "127",
                "CFBundleShortVersionString": "0.2.0",
            ],
            deviceInfo: DeviceInfoStub(),
            dismiss: { self.dismissInvokeCount += 1 }
        )
    }

    override func tearDown() {
        reportProblemServiceSpy = nil
        toastStateStore = nil
        dismissInvokeCount = nil
        sut = nil

        super.tearDown()
    }

    @MainActor
    func testFormSubmission_WhenSummaryHasLessThen10Characters_ItFailsValidation() async {
        await sut.handle(action: .textEntered(\.summary, text: "Hello"))
        await sut.handle(action: .submit)

        XCTAssertEqual(sut.state.scrollTo, .topInfoText)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(sut.state.summaryValidation, .failure("This field must be more than 10 characters"))

        await sut.handle(action: .scrollTo(element: nil))

        XCTAssertEqual(sut.state.scrollTo, nil)
    }

    @MainActor
    func testFormSubmission_WhenLogsToggleIsDisabled_WhenValidationSuccess_ItSendsRequestWithSuccess() async {
        let fields: [(WritableKeyPath<ReportProblemState, String>, String)] = [
            (\.summary, "summary"),
            (\.expectedResults, "expected results"),
            (\.actualResults, "actual results"),
            (\.stepsToReproduce, "steps to reproduce")
        ]

        await fields.asyncForEach { field, text in
            await sut.handle(action: .textEntered(field, text: "Hello \(text)!"))
        }

        XCTAssertEqual(sut.state.summary, "Hello summary!")
        XCTAssertEqual(sut.state.expectedResults, "Hello expected results!")
        XCTAssertEqual(sut.state.actualResults, "Hello actual results!")
        XCTAssertEqual(sut.state.stepsToReproduce, "Hello steps to reproduce!")

        await sut.handle(action: .sendLogsToggleSwitched(isEnabled: false))

        XCTAssertEqual(sut.state.sendLogsEnabled, false)

        await sut.handle(action: .submit)
        XCTAssertEqual(sut.state.isLoading, false)
        XCTAssertEqual(reportProblemServiceSpy.invokedSendWithReport, [
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
                includeLogs: false
            )
        ])
        XCTAssertEqual(toastStateStore.state.toasts, [.information(message: L10n.ReportProblem.successToast.string)])
        XCTAssertEqual(dismissInvokeCount, 1)
    }

    @MainActor
    func testFormSubmission_WhenValidationSuccess_ItSendsRequestWithFailureAndPresentsToast() async {
        reportProblemServiceSpy.error = .other(.sessionExpired)

        await sut.handle(action: .textEntered(\.summary, text: "Hello world!"))
        await sut.handle(action: .submit)
        XCTAssertEqual(reportProblemServiceSpy.invokedSendWithReport.count, 1)
        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: L10n.ReportProblem.failureToast.string)])
        XCTAssertEqual(dismissInvokeCount, 0)
    }

    @MainActor
    func testFormSubmission_WhenDeviceIsOffline_ItPresentsToast() async {
        reportProblemServiceSpy.error = .other(.network)

        await sut.handle(action: .textEntered(\.summary, text: "Hello world!"))
        await sut.handle(action: .submit)
        XCTAssertEqual(reportProblemServiceSpy.invokedSendWithReport.count, 1)
        XCTAssertEqual(toastStateStore.state.toasts, [.error(message: L10n.ReportProblem.offlineFailureToast.string)])
        XCTAssertEqual(dismissInvokeCount, 0)
    }

}

private extension Sequence {
    func asyncForEach(_ body: (Element) async -> Void) async {
        for element in self {
            await body(element)
        }
    }
}

private final class ReportProblemServiceSpy: ReportProblemService, @unchecked Sendable {
    var error: ActionError?
    private(set) var invokedSendWithReport: [IssueReport] = []

    func send(report: IssueReport) async throws(ActionError) {
        invokedSendWithReport.append(report)

        if let error {
            throw error
        }
    }
}

private class DeviceInfoStub: DeviceInfo {
    var model: String {
        "iPhone"
    }

    var systemName: String {
        "iOS"
    }

    var systemVersion: String {
        "18.4"
    }
}
