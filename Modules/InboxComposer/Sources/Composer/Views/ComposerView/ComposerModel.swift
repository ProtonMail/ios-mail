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

import Contacts
import InboxCore
import InboxCoreUI
import InboxContacts
import proton_app_uniffi
import SwiftUI

final class ComposerModel: ObservableObject {
    @Published private(set) var state: ComposerState
    @Published var toast: Toast?

    private let draft: AppDraftProtocol
    private let draftOrigin: DraftOrigin
    private let contactProvider: ComposerContactProvider
    private let pendingQueueProvider: PendingQueueProvider
    private let onSendingEvent: () -> Void
    private let permissionsHandler: ContactPermissionsHandler

    private let toCallback = ComposerRecipientCallbackWrapper()
    private let ccCallback = ComposerRecipientCallbackWrapper()
    private let bccCallback = ComposerRecipientCallbackWrapper()

    private var updateBodyDebounceTask: DebouncedTask?
    
    private var messageHasBeenSent: Bool = false

    var embeddedImageProvider: EmbeddedImageProvider {
        draft
    }

    init(
        draft: AppDraftProtocol,
        draftOrigin: DraftOrigin,
        contactProvider: ComposerContactProvider,
        pendingQueueProvider: PendingQueueProvider,
        onSendingEvent: @escaping () -> Void,
        permissionsHandler: CNContactStoring.Type,
        contactStore: CNContactStoring
    ) {
        self.draft = draft
        self.draftOrigin = draftOrigin
        self.contactProvider = contactProvider
        self.pendingQueueProvider = pendingQueueProvider
        self.onSendingEvent = onSendingEvent
        self.permissionsHandler = .init(permissionsHandler: permissionsHandler, contactStore: contactStore)
        self.state = .initial
        self.state = makeState(from: draft)
        setUpComposerRecipientListCallbacks()
    }

    @MainActor
    func onLoad() async {
        if draftOrigin == .cache {
            showToast(.information(message: L10n.Composer.draftLoadedOffline.string))
        }
        startEditingRecipients(for: .to)
        await permissionsHandler.requestAccessIfNeeded()
        await contactProvider.loadContacts()
    }

    @MainActor
    func viewWillDisappear() {
        AppLogger.log(message: "composer will disappear", category: .composer)
        if !messageHasBeenSent {
            showDraftSavedToastIfNeeded()
        }
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
        guard let result = contactProvider.contactsResult, !result.contacts.isEmpty else { return }

        contactProvider.filter(with: text) { result in
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
            showToast(.comingSoon)
        }
    }

    @MainActor
    func updateSubject(value: String) {
        switch draft.setSubject(subject: value) {
        case .ok:
            state = state.copy(\.subject, to: draft.subject())
        case .error(let draftError):
            AppLogger.log(error: draftError, category: .composer)
            showToast(.error(message: draftError.localizedDescription))
        }
    }

    @MainActor
    func updateBody(value: String) {
        guard !messageHasBeenSent else { return }
        debounce { [weak self] in  // FIXME: Move debounce to SDK
            guard let self else { return }
            switch draft.setBody(body: value) {
            case .ok:
                break
            case .error(let draftError):
                AppLogger.log(error: draftError, category: .composer)
                showToast(.error(message: draftError.localizedDescription))
            }
        }
    }

    @MainActor
    func sendMessage(dismissAction: Dismissable) {
        guard !messageHasBeenSent else { return }
        Task {
            guard await addHangingInputAsRecipientIfNeededAndContinueIfValid() else { return }
            await updateBodyDebounceTask?.executeImmediately()

            AppLogger.log(message: "sending message", category: .composer)
            switch await draft.send() {
            case .ok:
                messageHasBeenSent = true
                onSendingEvent()
                pendingQueueProvider.executeActionsInBackgroundTask()
                DispatchQueue.main.async {
                    dismissAction()
                }
            case .error(let draftError):
                AppLogger.log(error: draftError, category: .composer)
                if draftError.shouldBeDisplayed {
                    showToast(.error(message: draftError.localizedDescription))
                }
            }
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
            initialBody: draft.body()
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
        Dispatcher.dispatchOnMain(.init(
            block: { [weak self] in
                guard let self else { return }
                state.overrideRecipientState(for: group) { [weak self] in
                    guard let self else { return $0 }
                    let selectedIndexes = stateRecipientUIModels(for: group).selectedIndexes
                    let newRecipients = recipientUIModels(from: draft, for: group, selecting: selectedIndexes)
                    return $0.copy(\.recipients, to: newRecipients)
                }
            })
        )
    }

    private func stateRecipientUIModels(for group: RecipientGroupType) -> [RecipientUIModel] {
        switch group {
        case .to: state.toRecipients.recipients
        case .cc: state.ccRecipients.recipients
        case .bcc: state.bccRecipients.recipients
        }
    }

    @discardableResult
    private func addEntryInRecipients(
        for draft: AppDraftProtocol,
        entry: SingleRecipientEntry,
        group: RecipientGroupType
    ) -> ComposerRecipient? {
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
            return lastRecipient
        case .duplicate, .saveFailed: // FIXME: handle errors
            state.overrideRecipientState(for: group) {
                $0.copy(\.input, to: .empty)
                    .copy(\.controllerState, to: .editing)
            }
            showToast(.error(message: result.localizedErrorMessage(entry: entry).string))
            return nil
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

    private func addHangingInputAsRecipientIfNeededAndContinueIfValid() async -> Bool {
        guard let addedOneMoreRecipient = await addRecipientFromHangingInputIfNeeded() else { return true }
        if !addedOneMoreRecipient.isValid {
            showToast(.error(message: L10n.ComposerError.invalidLastRecipient.string))
        }
        return addedOneMoreRecipient.isValid
    }

    private func addRecipientFromHangingInputIfNeeded() async -> ComposerRecipient? {
        let recipientFields: [(state: RecipientFieldState, group: RecipientGroupType)] = [
            (state.toRecipients, .to),
            (state.ccRecipients, .cc),
            (state.bccRecipients, .bcc)
        ]
        guard let firstNonEmptyInput = recipientFields.first(where: { !$0.state.input.isEmpty }) else { return nil }
        let entry = SingleRecipientEntry(name: nil, email: firstNonEmptyInput.state.input)
        return addEntryInRecipients(for: draft, entry: entry, group: firstNonEmptyInput.group)
    }

    private func showDraftSavedToastIfNeeded() {
        Task {
            if case .ok(let id) = await draft.messageId() {
                if id != nil {
                    showToast(.information(message: L10n.Composer.draftSaved.string))
                }
            }
        }
    }

    private func debounce(_ block: @escaping () -> Void) {
        updateBodyDebounceTask?.cancel()
        updateBodyDebounceTask = DebouncedTask(duration: .seconds(2), block: block) { [weak self] in
            self?.updateBodyDebounceTask = nil
        }
        updateBodyDebounceTask?.debounce()
    }

    func showToast(_ toastToShow: Toast) {
        DispatchQueue.main.async { [weak self] in
            self?.toast = toastToShow
        }
    }
}

extension Draft: EmbeddedImageProvider {}
