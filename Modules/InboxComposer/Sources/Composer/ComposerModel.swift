// Copyright (c) 2024 Proton Technologies AG
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
import proton_app_uniffi
import SwiftUI

final class ComposerModel: ObservableObject {
    @Published var state: ComposerState
    private var contactProvider: ComposerContactProvider
    private let draft: DraftProtocol

    init(state: ComposerState = .initial, draft: DraftProtocol, contactProvider: ComposerContactProvider) { // FIXME: Remove state and inject directly a Draft object for tests when we have the final SDK
        self.state = state
        self.contactProvider = contactProvider
        self.draft = draft
        self.state = makeState(from: draft)
    }

    private func makeState(from draft: DraftProtocol) -> ComposerState {
        .init(
            toRecipients: .initialState(group: .to), // FIXME: when the SDK provides the ComposerRecipientList object
            ccRecipients: .initialState(group: .cc),
            bccRecipients: .initialState(group: .bcc),
            senderEmail: draft.sender(),
            subject: draft.subject(),
            body: draft.body()
        )
    }

    @MainActor
    func onLoad() async {
        startEditingRecipients(for: .to)
        await contactProvider.loadContacts()
    }

    @MainActor
    func startEditingRecipients(for group: RecipientGroupType) {
        endEditingRecipients()

        var newState = state
        newState.overrideRecipientState(for: group) {
            $0.copy(\.controllerState, to: .editing)
        }
        newState = newState.copy(\.editingRecipientsGroup, to: group)
        state = newState
    }

    @MainActor
    func endEditingRecipients() {
        state = state.copy(\.toRecipients, to: endEditing(group: state.toRecipients))
            .copy(\.ccRecipients, to: endEditing(group: state.ccRecipients))
            .copy(\.bccRecipients, to: endEditing(group: state.bccRecipients))
            .copy(\.editingRecipientsGroup, to: nil)
    }

    @MainActor
    func matchContact(group: RecipientGroupType, text: String) {
        state.overrideRecipientState(for: group) { $0.copy(\.input, to: text) }
        guard !contactProvider.contacts.isEmpty else { return }

        contactProvider.filter(with: text) {result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let newState: RecipientControllerStateType = result.matchingContacts.isEmpty ? .editing : .contactPicker
                state.overrideRecipientState(for: group) {
                    $0.copy(\.controllerState, to: newState)
                        .copy(\.input, to: result.text)
                        .copy(\.matchingContacts, to: result.matchingContacts)
                }
            }
        }
    }

    @MainActor
    func recipientToggleSelection(group: RecipientGroupType, index: Int) {
        state.updateRecipientState(for: group) { $0.recipients[index].isSelected.toggle() }
    }

    @MainActor
    func removeSelectedRecipients(group: RecipientGroupType) {
        state.updateRecipientState(for: group) { $0.recipients = $0.recipients.filter { $0.isSelected == false } }
    }

    @MainActor
    func selectLastRecipient(group: RecipientGroupType) {
        state.updateRecipientState(for: group) {
            guard !$0.recipients.isEmpty else { return }
            $0.recipients[$0.recipients.count - 1].isSelected = true
        }
    }

    @MainActor
    func addRecipient(group: RecipientGroupType, address: String) {
        // FIXME: call the SDK
        let newRecipient = RecipientUIModel(type: .single, address: address, isSelected: false, isValid: false, isEncrypted: false)
        state.overrideRecipientState(for: group) {
            $0.copy(\.recipients, to: $0.recipients + [newRecipient])
                .copy(\.input, to: .empty)
        }
    }

    @MainActor
    func addContact(group: RecipientGroupType, contact: ComposerContact) {
        // FIXME: create the correct recipient model, call the SDK
        let newRecipient = RecipientUIModel(
            type: contact.type.isGroup ? .group : .single,
            address: contact.type.isGroup ? contact.toUIModel().title : contact.toUIModel().subtitle,
            isSelected: false,
            isValid: true,
            isEncrypted: false
        )

        state.overrideRecipientState(for: group) {
            $0.copy(\.recipients, to: $0.recipients + [newRecipient])
                .copy(\.input, to: .empty)
                .copy(\.controllerState, to: .editing)
        }
    }

    // FIXME: when the SDK provides the ComposerRecipientList object and we can parse the whole draft
    @MainActor
    func changeSubject(value: String) {
        draft.setSubject(subject: value)
        state = state.copy(\.subject, to: draft.subject())
    }

    private func endEditing(group: RecipientFieldState) -> RecipientFieldState {
        var newRecipients = group.recipients
        group.recipients.indices.forEach { newRecipients[$0].isSelected = false }
        return group
            .copy(\.recipients, to: newRecipients)
            .copy(\.input, to: .empty)
            .copy(\.controllerState, to: .idle)
    }
}
