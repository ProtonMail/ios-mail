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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

final class ComposerModel: ObservableObject {
    @Published var state: ComposerState
    @Published var toast: Toast?

    private let draft: AppDraftProtocol
    private let contactProvider: ComposerContactProvider

    private let toCallback = ComposerRecipientCallbackWrapper()
    private let ccCallback = ComposerRecipientCallbackWrapper()
    private let bccCallback = ComposerRecipientCallbackWrapper()

    init(draft: AppDraftProtocol, contactProvider: ComposerContactProvider) {
        self.draft = draft
        self.contactProvider = contactProvider
        self.state = .initial
        self.state = makeState(from: draft)
        setUpComposerRecipientListCallbacks()
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
    func removeRecipientsThatAreSelected(group: RecipientGroupType) {
        let recipients: [RecipientUIModel] = {
            switch group {
            case .to: state.toRecipients.recipients
            case .cc: state.ccRecipients.recipients
            case .bcc: state.bccRecipients.recipients
            }
        }()
        let selected = recipients.filter(\.isSelected)
        removeRecipients(for: draft, group: group, recipients: selected)
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
        let entry = SingleRecipientEntry(name: nil, email: address)
        addEntryInRecipients(for: draft, entry: entry, group: group)
    }

    @MainActor
    func addContact(group: RecipientGroupType, contact: ComposerContact) {
        switch contact.type {
        case .single(let single):
            let entry = SingleRecipientEntry(name: single.name, email: single.email)
            addEntryInRecipients(for: draft, entry: entry, group: group)
        case .group:
            // FIXME: We are not ready to add groups because the SDK does not return them yet
            break
        }
    }

    @MainActor
    func updateSubject(value: String) {
        switch draft.setSubject(subject: value) {
        case .ok:
            state = state.copy(\.subject, to: draft.subject())
        case .error:
            // FIXME: handle error
            break
        }
    }
}

// MARK: Private

extension ComposerModel {

    private func makeState(from draft: AppDraftProtocol) -> ComposerState {
        .init(
            toRecipients: .initialState(group: .to, recipients: recipientUIModels(from: draft, for: .to)),
            ccRecipients: .initialState(group: .cc, recipients: recipientUIModels(from: draft, for: .cc)),
            bccRecipients: .initialState(group: .bcc, recipients: recipientUIModels(from: draft, for: .bcc)),
            senderEmail: draft.sender(),
            subject: draft.subject(),
            body: draft.body()
        )
    }

    private func recipientUIModels(
        from draft: AppDraftProtocol,
        for group: RecipientGroupType,
        selecting selectedIndexes: Set<Int> = []
    ) -> [RecipientUIModel] {
        let recipientList = recipientList(from: draft, group: group)
        return recipientList.recipients().enumerated().map { index, recipient in
            RecipientUIModel(composerRecipient: recipient, isSelected: selectedIndexes.contains(index))
        }
    }

    private func setUpComposerRecipientListCallbacks() {
        toCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .to) }
        ccCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .cc) }
        bccCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .bcc) }
        draft.toRecipients().setCallback(cb: toCallback)
        draft.ccRecipients().setCallback(cb: ccCallback)
        draft.bccRecipients().setCallback(cb: bccCallback)
    }

    private func updateStateRecipientUIModels(for group: RecipientGroupType) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            state.overrideRecipientState(for: group) { [weak self] in
                guard let self else { return $0 }
                let selectedIndexes = stateRecipientUIModels(for: group).selectedIndexes
                let newRecipients = recipientUIModels(from: draft, for: group, selecting: selectedIndexes)
                return $0.copy(\.recipients, to: newRecipients)
            }
        }
    }

    private func stateRecipientUIModels(for group: RecipientGroupType) -> [RecipientUIModel] {
        switch group {
        case .to: state.toRecipients.recipients
        case .cc: state.ccRecipients.recipients
        case .bcc: state.bccRecipients.recipients
        }
    }

    private func addEntryInRecipients(for draft: AppDraftProtocol, entry: SingleRecipientEntry, group: RecipientGroupType) {
        let recipientList = recipientList(from: draft, group: group)
        let result = recipientList.addSingleRecipient(recipient: entry)
        switch result {
        case .ok:
            let lastRecipient = recipientList.recipients().last!
            state.overrideRecipientState(for: group) {
                $0.copy(\.recipients, to: $0.recipients + [RecipientUIModel(composerRecipient: lastRecipient)])
                    .copy(\.input, to: .empty)
                    .copy(\.controllerState, to: .editing)
            }
        case .duplicate, .saveFailed: // FIXME: handle errors
            state.overrideRecipientState(for: group) {
                $0.copy(\.input, to: .empty)
                    .copy(\.controllerState, to: .editing)
            }
            toast = .error(message: result.localizedErrorMessage(entry: entry).string)
        }
    }

    private func removeRecipients(for draft: AppDraftProtocol, group: RecipientGroupType, recipients uiModels: [RecipientUIModel]) {
        let recipientList = recipientList(from: draft, group: group)
        for uiModel in uiModels {
            switch uiModel.composerRecipient {
            case .single(let single):
                recipientList.removeSingleRecipient(email: single.address)
            case .group(let group):
                recipientList.removeGroup(groupName: group.displayName)
            }
        }
        let uiModelsAfterRemove = recipientUIModels(from: draft, for: group)
        state.updateRecipientState(for: group) { $0.recipients = uiModelsAfterRemove }
    }

    private func endEditing(group: RecipientFieldState) -> RecipientFieldState {
        var newRecipients = group.recipients
        group.recipients.indices.forEach { newRecipients[$0].isSelected = false }
        return group
            .copy(\.recipients, to: newRecipients)
            .copy(\.input, to: .empty)
            .copy(\.controllerState, to: .idle)
    }

    private func recipientList(from draft: AppDraftProtocol, group: RecipientGroupType) -> ComposerRecipientListProtocol {
        switch group {
        case .to:
            draft.toRecipients()
        case .cc:
            draft.ccRecipients()
        case .bcc:
            draft.bccRecipients()
        }
    }
}
