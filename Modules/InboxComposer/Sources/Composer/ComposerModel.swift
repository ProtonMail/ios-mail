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
import SwiftUI

final class ComposerModel: ObservableObject {
    @Published var state: ComposerState
    private var contactProvider: ComposerContactProvider

    init(state: ComposerState = .initial, contactProvider: ComposerContactProvider = .mockInstance) {
        self.state = state
        self.contactProvider = contactProvider
    }

    func startEditingRecipients(for group: RecipientGroupType) {
        state.overrideRecipientState(for: group) {
            $0.copy(\.controllerState, to: .editing)
        }
        state.editingRecipientsGroup = group
    }

    @MainActor
    func matchContact(group: RecipientGroupType, text: String) {
        let matchingContacts = contactProvider.filter(with: text)
        let newState: RecipientControllerStateType = matchingContacts.isEmpty ? .editing : .contactPicker
        state.overrideRecipientState(for: group) {
            $0.copy(\.controllerState, to: newState)
                .copy(\.input, to: text)
                .copy(\.matchingContacts, to: matchingContacts)
        }
    }

    func recipientToggleSelection(group: RecipientGroupType, index: Int) {
        state.updateRecipientState(for: group) { $0.recipients[index].isSelected.toggle() }
    }

    func removeSelectedRecipients(group: RecipientGroupType) {
        state.updateRecipientState(for: group) { $0.recipients = $0.recipients.filter { $0.isSelected == false } }
    }

    func selectLastRecipient(group: RecipientGroupType) {
        state.updateRecipientState(for: group) {
            guard !$0.recipients.isEmpty else { return }
            $0.recipients[$0.recipients.count - 1].isSelected = true
        }
    }

    func addRecipient(group: RecipientGroupType, address: String) {
        // FIXME: call the SDK
        let newRecipient = RecipientUIModel(type: .single, address: address, isSelected: false, isValid: false, isEncrypted: false)
        state.overrideRecipientState(for: group) {
            $0.copy(\.recipients, to: $0.recipients + [newRecipient])
                .copy(\.input, to: .empty)
        }
    }

    func addContact(group: RecipientGroupType, contact: ComposerContact) {
        // FIXME: create the correct recipient model, call the SDK
        let newRecipient = RecipientUIModel(
            type: contact.type.isGroup ? .group : .single,
            address: contact.type.isGroup ? contact.uiModel.title : contact.uiModel.subtitle,
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

    func finishEditing(group: RecipientGroupType) {
        state.overrideRecipientState(for: group) {
            var newRecipients = $0.recipients
            $0.recipients.indices.forEach { newRecipients[$0].isSelected = false }
            return $0
                .copy(\.recipients, to: newRecipients)
                .copy(\.input, to: .empty)
                .copy(\.controllerState, to: .idle)
        }
        state.editingRecipientsGroup = nil
    }
}
