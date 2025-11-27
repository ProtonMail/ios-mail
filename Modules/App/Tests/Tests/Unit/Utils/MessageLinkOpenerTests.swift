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

import InboxCoreUI
import InboxTesting
import SwiftUI
import Testing

@testable import ProtonMail

@MainActor
final class MessageLinkOpenerTests {
    private var confirmationAlert = Binding<AlertModel?>(wrappedValue: nil)
    private let urlOpener = EnvironmentURLOpenerSpy()
    private let testURL = URL(string: "https://example.com")!

    @Test
    func whenConfirmLinkIsDisabled_opensLinkImmediately() throws {
        let sut = makeSUT(confirmLink: false)

        sut.action(testURL)

        #expect(confirmationAlert.wrappedValue == nil)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [testURL])
    }

    @Test
    func whenConfirmLinkIsEnabled_askForConfirmation() async throws {
        let sut = makeSUT(confirmLink: true)

        sut.action(testURL)

        let alert = try #require(confirmationAlert.wrappedValue)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [])

        let confirmAction = try #require(alert.actions.first { $0.buttonRole == .destructive })
        await confirmAction.action()

        #expect(confirmationAlert.wrappedValue == nil)
        #expect(urlOpener.callAsFunctionInvokedWithURL == [testURL])
    }

    private func makeSUT(confirmLink: Bool) -> MessageLinkOpener {
        .init(
            confirmLink: confirmLink,
            confirmationAlert: confirmationAlert,
            openURL: urlOpener
        )
    }
}
