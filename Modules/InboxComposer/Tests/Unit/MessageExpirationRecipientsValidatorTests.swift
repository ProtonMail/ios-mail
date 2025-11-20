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
final class MessageExpirationRecipientsValidatorTests {
    private lazy var sut = MessageExpirationRecipientsValidator(alertBinding: binding)
    private var alertModel: AlertModel? = nil
    private lazy var binding = Binding<AlertModel?>(get: { self.alertModel }, set: { self.alertModel = $0 })

    private let dummyCustomDate = UnixTimestamp(Date.now.timeIntervalSince1970)
    private let oneDummyAddress = ["a@example.com"]
    private let twoDummyAddresses = ["b@example.com", "c@example.com"]
    private let threeDummyAddresses = ["d@example.com", "e@example.com", "f@example.com"]

    @Test
    func testValidate_whenExpirationNever_itShouldProceedWithoutAlert() async {
        let draft = mockDraft(expirationTimeResult: .ok(.never))
        let result = await sut.validateRecipientsIfMessageHasExpiration(draft: draft)

        #expect(result == .proceed)
        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenNoUnsupportedOrUnknown_ItShouldProceedWithoutAlert() async {
        let draft = mockDraft(expirationTimeResult: .ok(.custom(dummyCustomDate)))
        let result = await sut.validateRecipientsIfMessageHasExpiration(draft: draft)

        #expect(result == .proceed)
        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenAllUnsupported_itShouldShowAlert() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: [], unsupported: twoDummyAddresses, unknown: []))
        )

        Task {
            await sut.validateRecipientsIfMessageHasExpiration(draft: draft)
        }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.message == L10n.MessageExpiration.alertUnsupportedForAllRecipientsMessage)
    }

    @Test
    func testValidate_whenOneUnsupported_butAlsoOneSupported_itShouldShowAlert() async {
        let unsuportedAddress = [twoDummyAddresses.first!]
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: oneDummyAddress, unsupported: unsuportedAddress, unknown: []))
        )

        Task {
            await sut.validateRecipientsIfMessageHasExpiration(draft: draft)
        }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(
            alertModel?.message?.string
                == L10n
                .MessageExpiration
                .alertUnsupportedForSomeRecipientsMessage(addresses: unsuportedAddress.first!)
                .string
        )
    }

    @Test
    func testValidate_whenMultipleUnsupported_butAlsoSomeSupported_itShouldShowAlert() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: oneDummyAddress, unsupported: threeDummyAddresses + twoDummyAddresses, unknown: []))
        )

        Task {
            await sut.validateRecipientsIfMessageHasExpiration(draft: draft)
        }
        await Task.yield()

        #expect(alertModel != nil)
        let expectedListOfAddresses = threeDummyAddresses.joined(separator: ", ") + ", " + CommonL10n.plusMore(count: 2).string
        #expect(
            alertModel?.message?.string
                == L10n
                .MessageExpiration
                .alertUnsupportedForSomeRecipientsMessage(addresses: expectedListOfAddresses)
                .string
        )
    }

    @Test
    func testValidate_whenAllUnknown_itShouldShowAlert() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: [], unsupported: [], unknown: twoDummyAddresses))
        )

        Task { await sut.validateRecipientsIfMessageHasExpiration(draft: draft) }
        await Task.yield()

        #expect(alertModel != nil)
        #expect(alertModel?.message == L10n.MessageExpiration.alertUnknownSupportForAllRecipientsMessage)
    }

    @Test
    func testValidate_whenSendAnywayIsSelected_itShouldProceed() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: [], unsupported: twoDummyAddresses, unknown: []))
        )

        let task = Task { await sut.validateRecipientsIfMessageHasExpiration(draft: draft) }
        await Task.yield()

        await selectActionForTitle(resource: L10n.MessageExpiration.sendAnyway)

        let result = await task.value
        #expect(result == .proceed)
        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenAddPasswordIsSelected_itShouldReturnDoNotProceedAddPassword() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: [], unsupported: twoDummyAddresses, unknown: []))
        )

        let task = Task { await sut.validateRecipientsIfMessageHasExpiration(draft: draft) }
        await Task.yield()

        await selectActionForTitle(resource: L10n.MessageExpiration.addPassword)

        let result = await task.value
        #expect(result == .doNotProceed(addPassword: true))
        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenCancelIsSelected_ItShouldNotProceed() async {
        let draft = mockDraft(
            expirationTimeResult: .ok(.custom(dummyCustomDate)),
            validationResult: .ok(.init(supported: [], unsupported: twoDummyAddresses, unknown: []))
        )

        let task = Task { await sut.validateRecipientsIfMessageHasExpiration(draft: draft) }
        await Task.yield()

        await selectActionForTitle(resource: CommonL10n.cancel)

        let result = await task.value
        #expect(result == .doNotProceed(addPassword: false))
        #expect(alertModel == nil)
    }

    @Test
    func testValidate_whenDraftReturnsError_itShouldNotProceed() async {
        let draft = mockDraft(expirationTimeResult: .error(.network))
        let result = await sut.validateRecipientsIfMessageHasExpiration(draft: draft)

        #expect(result == .doNotProceed(addPassword: false))
        #expect(alertModel == nil)
    }
}

private extension MessageExpirationRecipientsValidatorTests {

    private func mockDraft(
        expirationTimeResult: DraftExpirationTimeResult,
        validationResult: DraftValidateRecipientsExpirationFeatureResult = .ok(.init(supported: [], unsupported: [], unknown: []))
    ) -> AppDraftProtocol {
        let mockDraft = MockDraft.emptyMockDraft
        mockDraft.mockDraftExpirationTimeResult = expirationTimeResult
        mockDraft.mockValidateRecipientsExpirationResult = validationResult
        return mockDraft
    }

    private func selectActionForTitle(resource: LocalizedStringResource) async {
        if let action = alertModel?.actions.first(where: { $0.title.string == resource.string }) {
            await action.action()
        } else {
            Issue.record("action not found for \(resource)")
        }
    }
}
