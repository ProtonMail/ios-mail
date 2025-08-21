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
import InboxTesting
import proton_app_uniffi
import SwiftUI
import Testing

@MainActor
final class MessageLinkOpenerTests {
    private var stubbedMailSettings = MailSettings.defaults()
    private var confirmationAlert = ObservableBag<AlertModel?>(wrappedValue: nil)
    private let urlOpener = EnvironmentURLOpenerSpy()
    private let testURL = URL(string: "https://example.com")!

    private lazy var sut = MessageLinkOpener(
        mailSettings: { [unowned self] in await stubbedMailSettings },
        confirmationAlert: confirmationAlert.bind(),
        openURL: urlOpener
    )

    @Test
    func whenConfirmLinkIsDisabled_opensLinkImmediately() async throws {
        stubbedMailSettings.confirmLink = false

        sut.action(testURL)

        try await waitForActionToTakeEffect()

        #expect(confirmationAlert.wrappedValue == nil)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [testURL])
    }

    @Test
    func whenConfirmLinkIsEnabled_askForConfirmation() async throws {
        stubbedMailSettings.confirmLink = true

        sut.action(testURL)

        try await waitForActionToTakeEffect()

        let alert = try #require(confirmationAlert.wrappedValue)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [])

        let confirmAction = try #require(alert.actions.first { $0.buttonRole == .destructive })
        await confirmAction.action()

        #expect(confirmationAlert.wrappedValue == nil)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [testURL])
    }

    private func waitForActionToTakeEffect() async throws {
        try await withTimeout { [confirmationAlert, urlOpener] in
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = confirmationAlert.wrappedValue
                    _ = urlOpener.callAsFunctionInvokedWithURL
                } onChange: {
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
@Observable
private class ObservableBag<Value> {
    private(set) var wrappedValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    func bind() -> Binding<Value> {
        .init {
            self.wrappedValue
        } set: { newValue in
            self.wrappedValue = newValue
        }
    }
}
