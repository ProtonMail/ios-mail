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
import InboxCore
@preconcurrency import InboxCoreUI
import SwiftUI
import Testing
import proton_app_uniffi

@testable import InboxComposer

@MainActor
final class SenderAddressValidatorTests {
    private lazy var sut = SenderAddressValidator(alertBinding: binding)
    private var alertModel: AlertModel? = nil
    private lazy var binding = Binding<AlertModel?>(get: { self.alertModel }, set: { self.alertModel = $0 })

    private let dummyEmail = "test@example.com"

    @Test
    func testValidate_whenNoAddressValidationResult_itShouldNotShowAlert() async {
        let draft = mockDraft(addressValidationResult: nil)
        await sut.validate(draft: draft)

        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenCanNotSendError_itShouldShowAlert() async throws {
        let validationError = DraftAddressValidationResult(email: dummyEmail, error: .canNotSend)
        let draft = mockDraft(addressValidationResult: validationError)

        let task = Task { await sut.validate(draft: draft) }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.title.string == L10n.SenderValidation.addressNotAvailableAlertTitle.string)
        #expect(alertModel?.message?.string == L10n.SenderValidation.cannotSend(address: dummyEmail).string)

        try await dismissAlert()
        await task.value

        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenCanNotReceiveError_itShouldShowAlert() async throws {
        let validationError = DraftAddressValidationResult(email: dummyEmail, error: .canNotReceive)
        let draft = mockDraft(addressValidationResult: validationError)

        let task = Task { await sut.validate(draft: draft) }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.message?.string == L10n.SenderValidation.cannotSend(address: dummyEmail).string)

        try await dismissAlert()
        await task.value
    }

    @Test
    func testValidate_whenDisabledError_itShouldShowAlert() async throws {
        let validationError = DraftAddressValidationResult(email: dummyEmail, error: .disabled)
        let draft = mockDraft(addressValidationResult: validationError)

        let task = Task { await sut.validate(draft: draft) }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.message?.string == L10n.SenderValidation.disabled(address: dummyEmail).string)

        try await dismissAlert()
        await task.value
    }

    @Test
    func testValidate_whenSubscriptionRequiredError_itShouldShowAlert() async throws {
        let validationError = DraftAddressValidationResult(email: dummyEmail, error: .subscriptionRequired)
        let draft = mockDraft(addressValidationResult: validationError)

        let task = Task { await sut.validate(draft: draft) }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.message?.string == L10n.SenderValidation.subscriptionRequired(address: dummyEmail).string)

        try await dismissAlert()
        await task.value
    }

    @Test
    func testValidate_shouldClearAddressValidationError() async {
        let validationError = DraftAddressValidationResult(email: dummyEmail, error: .disabled)
        let draft = mockDraft(addressValidationResult: validationError)

        Task { await sut.validate(draft: draft) }
        await Task.yield()

        #expect(draft.clearAddressValidationErrorWasCalled)
    }
}

private extension SenderAddressValidatorTests {
    private func mockDraft(addressValidationResult: DraftAddressValidationResult?) -> MockDraft {
        let mockDraft = MockDraft.emptyMockDraft
        mockDraft.mockDraftAddressValidationResult = addressValidationResult
        return mockDraft
    }

    private func dismissAlert() async throws {
        let action = try #require(alertModel?.actions.first)
        await action.action()
    }
}
