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
import InboxContacts
import InboxCore
import InboxCoreUI
import PhotosUI
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

import struct ProtonCoreUtilities.NestedObservableObject

typealias Nested = NestedObservableObject

@MainActor
final class ComposerModel: ObservableObject {
    @Published private(set) var state: ComposerState
    @Published var bodyAction: ComposerBodyAction?
    @Published var modalAction: ComposerViewModalState?
    @Nested var attachmentAlertState: AttachmentAlertState
    @Published var toast: Toast?

    private let draft: AppDraftProtocol
    private let draftOrigin: DraftOrigin
    private let contactProvider: ComposerContactProvider
    private let onDismiss: (ComposerDismissReason) -> Void
    private let permissionsHandler: ContactPermissionsHandler
    private let photosItemsHandler: PhotosPickerItemHandler
    private let cameraImageHandler: CameraImageHandler
    private let fileItemsHandler: FilePickerItemHandler
    private let scheduleSendOptionsProvider: ScheduleSendOptionsProvider
    private let expirationValidationActions: MessageExpirationValidatorActions
    private let senderAddressValidatorActions: SenderAddressValidatorActions

    private lazy var senderAddressValidator = SenderAddressValidator(
        alertBinding: alertBinding,
        actions: senderAddressValidatorActions
    )
    private lazy var messageExpirationRecipientsValidator = MessageExpirationRecipientsValidator(
        alertBinding: alertBinding,
        actions: expirationValidationActions
    )
    lazy var invalidAddressAlertStore = InvalidAddressAlertStateStore(
        validator: .init(
            readState: { [weak self] in return self?.state },
            composerWillDismiss: { [weak self] in return self?.composerWillDismiss ?? false }
        ),
        alertBinding: alertBinding
    )

    var alertBinding: Binding<AlertModel?> {
        .init(
            get: { [weak self] in self?.state.alert },
            set: { [weak self] newValue in
                guard let self else { return }
                state = state.copy(\.alert, to: newValue)
            }
        )
    }

    private let toCallback = ComposerRecipientCallbackWrapper()
    private let ccCallback = ComposerRecipientCallbackWrapper()
    private let bccCallback = ComposerRecipientCallbackWrapper()
    private var attachmentWatcher: DraftAttachmentWatcher?

    private var updateBodyDebounceTask: DebouncedTask?

    private var inlineAttachmentsTransformed = Set<String>()
    private var messageHasBeenSentOrScheduled: Bool = false
    private var composerWillDismiss: Bool = false

    var imageProxy: ImageProxy {
        draft
    }

    init(
        draft: AppDraftProtocol,
        draftOrigin: DraftOrigin,
        contactProvider: ComposerContactProvider,
        onDismiss: @escaping (ComposerDismissReason) -> Void,
        contactStore: CNContactStoring,
        photosItemsHandler: PhotosPickerItemHandler,
        cameraImageHandler: CameraImageHandler,
        fileItemsHandler: FilePickerItemHandler,
        isAddingAttachmentsEnabled: Bool,
        expirationValidationActions: MessageExpirationValidatorActions = .productionInstance,
        senderAddressValidatorActions: SenderAddressValidatorActions = .productionInstance
    ) {
        self.draft = draft
        self.draftOrigin = draftOrigin
        self.contactProvider = contactProvider
        self.onDismiss = onDismiss
        self.permissionsHandler = .init(contactStore: contactStore)
        self.state = .initial(composerMode: draft.composerMode, isAddingAttachmentsEnabled: isAddingAttachmentsEnabled)
        self.photosItemsHandler = photosItemsHandler
        self.cameraImageHandler = cameraImageHandler
        self.fileItemsHandler = fileItemsHandler
        self.attachmentAlertState = .init()
        self.scheduleSendOptionsProvider = .init(scheduleSendOptions: draft.scheduleSendOptions)
        self.expirationValidationActions = expirationValidationActions
        self.senderAddressValidatorActions = senderAddressValidatorActions
        self.state = makeState(from: draft)

        setUpCallbacks()
    }

    deinit {
        attachmentWatcher?.disconnect()
    }

    func onLoad() async {
        if draftOrigin == .cache {
            showToast(.information(message: L10n.Composer.draftLoadedOffline.string))
        }
        await permissionsHandler.requestAccessIfNeeded()
        await contactProvider.loadContacts()
        await senderAddressValidator.validate(draft: draft)
        await updateStateAttachmentUIModels()
        setInitialFocus()
    }

    private func setInitialFocus() {
        if state.toRecipients.recipients.isEmpty {
            startEditingRecipients(for: .to)
            return
        }
        state.isInitialFocusInBody = true
    }

    func viewDidDisappear() async {
        AppLogger.log(message: "composer did disappear", category: .composer)
        await updateBodyDebounceTask?.executeImmediately()
        if !messageHasBeenSentOrScheduled {
            onDismiss(.dismissedManually(savedDraftId: await draftMessageId()))
        }
    }

    func startEditingRecipients(for group: RecipientGroupType) {
        guard invalidAddressAlertStore.validateAndShowAlertIfNeeded() else { return }
        endEditingRecipients()

        var newState = state
        newState.overrideRecipientState(for: group) { recipientFieldState in
            recipientFieldState.copy(\.controllerState, to: .editing)
        }
        newState = newState.copy(\.editingRecipientsGroup, to: group)
        RecipientGroupType.allCases(excluding: group).forEach { group in
            newState.overrideRecipientState(for: group) { recipientFieldState in
                recipientFieldState.copy(\.controllerState, to: .expanded)
            }
        }

        state = newState
    }

    func endEditingRecipients() {
        guard invalidAddressAlertStore.recipientAddressValidator.canResignFocus() else { return }
        addRecipientFromInput()
        state = state.copy(\.toRecipients, to: endEditing(group: state.toRecipients))
            .copy(\.ccRecipients, to: endEditing(group: state.ccRecipients))
            .copy(\.bccRecipients, to: endEditing(group: state.bccRecipients))
            .copy(\.editingRecipientsGroup, to: nil)
    }

    func matchContact(group: RecipientGroupType, text: String) {
        state.overrideRecipientState(for: group) { recipientFieldState in recipientFieldState.copy(\.input, to: text) }
        guard let result = contactProvider.contactsResult, !result.contacts.isEmpty else { return }

        contactProvider.filter(with: text) { result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let newState: RecipientControllerStateType = result.matchingContacts.isEmpty ? .editing : .contactPicker
                state.overrideRecipientState(for: group) { recipientFieldState in
                    recipientFieldState.copy(\.controllerState, to: newState)
                        .copy(\.input, to: result.text)
                        .copy(\.matchingContacts, to: result.matchingContacts)
                }
            }
        }
    }

    func recipientToggleSelection(group: RecipientGroupType, index: Int) {
        state.updateRecipientState(for: group) { recipientFieldState in
            recipientFieldState.recipients[index].isSelected.toggle()
        }
    }

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

    func selectLastRecipient(group: RecipientGroupType) {
        state.updateRecipientState(for: group) { recipientFieldState in
            guard !recipientFieldState.recipients.isEmpty else { return }
            recipientFieldState.recipients[recipientFieldState.recipients.count - 1].isSelected = true
        }
    }

    func addRecipientFromInput() {
        guard
            invalidAddressAlertStore.validateAndShowAlertIfNeeded(),
            let input = state.editingRecipientFieldState?.input.withoutWhitespace, !input.isEmpty,
            let group = state.editingRecipientsGroup
        else {
            return
        }
        let singleRecipient = newRecipient(email: input)
        addEntryInRecipients(for: draft, entry: singleRecipient, group: group)
    }

    func addContact(group: RecipientGroupType, contact: ComposerContact) {
        switch contact.type {
        case .single(let single):
            let entry = SingleRecipientEntry(name: single.name, email: single.email)
            addEntryInRecipients(for: draft, entry: entry, group: group)
        case .group(let contactGroup):
            addContactGroupInRecipients(
                contactGroupName: contactGroup.name,
                recipients: contactGroup.entries.map { entry in SingleRecipientEntry(name: entry.name, email: entry.email) },
                total: UInt64(contactGroup.totalMembers),
                group: group
            )
        }
    }

    func updateSubject(value: String) {
        switch draft.setSubject(subject: value) {
        case .ok:
            state = state.copy(\.subject, to: draft.subject())
        case .error(let draftError):
            AppLogger.log(error: draftError, category: .composer)
            showToast(.error(message: draftError.localizedDescription))
        }
    }

    func updateBody(value: String) {
        guard !messageHasBeenSentOrScheduled else { return }
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

    func reloadBodyAfterMemoryPressure() async {
        await reloadBody(clearImageCacheFirst: false)
    }

    func scheduleSendState(lastScheduledTime: UInt64?) -> ComposerViewModalState? {
        do {
            let timeOptions = try scheduleSendOptionsProvider.scheduleSendOptions().get()
            let predefinedOptions = [timeOptions.tomorrowTime, timeOptions.mondayTime]
            var previouslySet: UInt64? = nil
            if let lastScheduledTime, !predefinedOptions.contains(lastScheduledTime) {
                previouslySet = lastScheduledTime
            }
            return .scheduleSend(timeOptions, lastScheduledTime: previouslySet)
        } catch let error {
            toast = .error(message: error.localizedDescription)
            return nil
        }
    }

    func passwordProtectionState() -> ComposerViewModalState? {
        switch draft.getPassword() {
        case .ok(let draftPassword):
            let password = draftPassword?.password ?? ""
            let hint = draftPassword?.hint ?? ""
            return .passwordProtection(password: password, hint: hint)
        case .error(let error):
            toast = .error(message: error.localizedDescription)
            return nil
        }
    }

    private func proceedAfterMessageExpirationValidation() async -> Bool {
        switch await messageExpirationRecipientsValidator.validateRecipientsIfMessageHasExpiration(draft: draft) {
        case .proceed:
            return true
        case .doNotProceed(let addPassword):
            if addPassword {
                modalAction = passwordProtectionState()
            }
            return false
        }
    }

    func sendMessage(at date: Date? = nil, dismissAction: Dismissable) async {
        addRecipientFromInput()
        guard !invalidAddressAlertStore.isAlertShown else { return }
        guard !messageHasBeenSentOrScheduled else { return }
        await updateBodyDebounceTask?.executeImmediately()
        guard await proceedAfterMessageExpirationValidation() else { return }

        switch await performSendOrSchedule(date: date) {
        case .ok:
            messageHasBeenSentOrScheduled = true
            dismissComposer(dismissAction: dismissAction, reason: await dismissReasonAfterSend(isScheduled: date != nil))
        case .error(let draftError):
            AppLogger.log(error: draftError, category: .composer)
            if draftError.shouldBeDisplayed {
                showToast(.error(message: draftError.localizedDescription))
            }
        }
    }

    func addAttachments(selectedPhotosItems items: [PhotosPickerItemTransferable]) async {
        guard !items.isEmpty else { return }
        let result = await photosItemsHandler.addPickerPhotos(to: draft, photos: items)
        bodyAction = .insertInlineImages(cids: result.successfulContentIds)
        attachmentAlertState.enqueueAlertsForFailedAttachmentAdditions(errors: result.errors)
    }

    func addAttachments(filePickerResult: Result<[URL], any Error>) async {
        await fileItemsHandler.addSelectedFiles(to: draft, selectionResult: filePickerResult) { errors in
            attachmentAlertState.enqueueAlertsForFailedAttachmentAdditions(errors: errors)
        }
    }

    func addAttachments(image: UIImage) async {
        do {
            switch draft.composerMode {
            case .html:
                let cid = try await cameraImageHandler.addInlineImage(to: draft, image: image)
                bodyAction = .insertInlineImages(cids: [cid])

            case .plainText:
                try await cameraImageHandler.addRegularAttachment(to: draft, image: image)
            }
        } catch {
            attachmentAlertState.enqueueAlertsForFailedAttachmentAdditions(errors: [error])
        }
    }

    func transformInlineAttachmentToRegular(cid: String) async {
        switch await draft.attachmentList().swapAttachmentDisposition(contentId: cid) {
        case .ok:
            inlineAttachmentsTransformed.insert(cid)
            bodyAction = .removeInlineImage(cid: cid)
        case .error(let error):
            let message = "Failed to transform inline attachment to regular attachment: \(error)"
            AppLogger.log(message: message, category: .composer, isError: true)
            showToast(.error(message: error.localizedDescription))
        }
    }

    func removeAttachment(attachment: AttachmentMetadata) async {
        do {
            try await draft.attachmentList().remove(id: attachment.id).get()
            if attachment.disposition == .inline {
                await reloadBody(clearImageCacheFirst: true)
            }
        } catch {
            AppLogger.log(error: error, category: .composer)
        }
    }

    func removeAttachment(cid: String) async {
        guard !inlineAttachmentsTransformed.contains(cid) else { return }
        switch await draft.attachmentList().removeWithCid(contentId: cid) {
        case .ok:
            bodyAction = .removeInlineImage(cid: cid)
        case .error(let error):
            let message = "Failed to remove attachment from draft using cid: \(error)"
            AppLogger.log(message: message, category: .composer, isError: true)
        }
    }

    func removeAttachments(for error: AttachmentErrorAlertModel) async {
        if case .uploading(let uploadAttachmentErrors) = error.origin {
            for error in uploadAttachmentErrors {
                await removeAttachment(attachment: error.attachment)
            }
        }
    }

    func setPasswordProtection(password: String, hint: String?) async {
        switch await draft.setPassword(password: password, hint: hint) {
        case .ok:
            state = state.copy(\.isPasswordProtected, to: draftIsPasswordProtected(draft: draft))
        case .error(let error):
            showToast(.error(message: error.localizedDescription))
        }
    }

    func removePasswordProtection() async {
        switch await draft.removePassword() {
        case .ok:
            state = state.copy(\.isPasswordProtected, to: draftIsPasswordProtected(draft: draft))
        case .error(let error):
            showToast(.error(message: error.localizedDescription))
        }
    }

    func setExpirationTime(_ time: DraftExpirationTime) async {
        switch await draft.setExpirationTime(expirationTime: time) {
        case .ok:
            state = state.copy(\.expirationTime, to: draftExpirationTime(draft: draft))
        case .error(let error):
            showToast(.error(message: error.localizedDescription))
        }
    }

    func discardDraft(dismissAction: Dismissable) async {
        // execute pending saves before any discard operation
        await updateBodyDebounceTask?.executeImmediately()
        state.alert = .discardDraft(action: { @MainActor [weak self] action in
            defer { self?.state.alert = nil }
            guard let self, action == .discard else { return }
            switch await draft.discard() {
            case .ok:
                dismissComposer(dismissAction: dismissAction, reason: .draftDiscarded)
            case .error(let error):
                showToast(.error(message: error.localizedDescription))
            }
        })
    }

    func dismissComposerManually(dismissAction: Dismissable) async {
        await updateBodyDebounceTask?.executeImmediately()
        let messageId = await draftMessageId()
        dismissComposer(dismissAction: dismissAction, reason: .dismissedManually(savedDraftId: messageId))
    }
}

extension ComposerModel: ChangeSenderHandlerProtocol {
    func listSenderAddresses() async throws -> DraftSenderAddressList {
        try await draft.listSenderAddresses().get()
    }

    func changeSenderAddress(email: String) async throws {
        guard !messageHasBeenSentOrScheduled else { return }
        await updateBodyDebounceTask?.executeImmediately()
        switch await draft.changeSenderAddress(email: email) {
        case .ok:
            let attachments = try await draft.attachmentList().attachments().get().toDraftAttachmentUIModels()
            state = makeState(from: draft, attachments: attachments)
            bodyAction = .reloadBody(html: state.initialBody, clearImageCacheFirst: false)
        case .error(let error):
            throw error
        }
    }
}

// MARK: Private

extension ComposerModel {
    private func draftMessageId() async -> Id? {
        try? await draft.messageId().get()
    }

    private func draftIsPasswordProtected(draft: AppDraftProtocol) -> Bool {
        switch draft.isPasswordProtected() {
        case .ok(let value):
            return value
        case .error(let error):
            AppLogger.log(error: error, category: .composer)
            return false
        }
    }

    private func draftExpirationTime(draft: AppDraftProtocol) -> DraftExpirationTime {
        switch draft.expirationTime() {
        case .ok(let time):
            return time
        case .error(let error):
            AppLogger.log(error: error, category: .composer)
            return .never
        }
    }

    private func makeState(from draft: AppDraftProtocol, attachments: [DraftAttachmentUIModel] = []) -> ComposerState {
        .init(
            composerMode: draft.composerMode,
            toRecipients: .initialState(group: .to, recipients: recipientUIModels(from: draft, for: .to)),
            ccRecipients: .initialState(group: .cc, recipients: recipientUIModels(from: draft, for: .cc)),
            bccRecipients: .initialState(group: .bcc, recipients: recipientUIModels(from: draft, for: .bcc)),
            senderEmail: draft.sender(),
            subject: draft.subject(),
            attachments: attachments,
            initialBody: draft.body(),
            isInitialFocusInBody: false,
            isAddingAttachmentsEnabled: state.isAddingAttachmentsEnabled,
            isPasswordProtected: draftIsPasswordProtected(draft: draft),
            expirationTime: draftExpirationTime(draft: draft)
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

    private func setUpCallbacks() {
        toCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .to) }
        ccCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .cc) }
        bccCallback.delegate = { [weak self] in self?.updateStateRecipientUIModels(for: .bcc) }
        draft.toRecipients().setCallback(cb: toCallback)
        draft.ccRecipients().setCallback(cb: ccCallback)
        draft.bccRecipients().setCallback(cb: bccCallback)

        Task {
            let attachmentsCallback = AsyncLiveQueryCallbackWrapper {
                [weak self] in await self?.updateStateAttachmentUIModels()
            }
            // FIXME: The SDK should provide a sync function to set the callback
            switch await draft.attachmentList().watcher(callback: attachmentsCallback) {
            case .ok(let watcher):
                attachmentWatcher = watcher
            case .error(let error):
                AppLogger.log(error: error, category: .composer)
            }
        }
    }

    private func updateStateRecipientUIModels(for group: RecipientGroupType) {
        Dispatcher.dispatchOnMain(
            .init(block: { [weak self] in
                guard let self else { return }
                state.overrideRecipientState(for: group) { [weak self] recipientFieldState in
                    guard let self else { return recipientFieldState }
                    let selectedIndexes = stateRecipientUIModels(for: group).selectedIndexes
                    let newRecipients = recipientUIModels(from: draft, for: group, selecting: selectedIndexes)
                    if newRecipients.hasNewDoesNotExistAddressError(comparedTo: recipientFieldState.recipients) {
                        showToast(.error(message: L10n.ComposerError.addressDoesNotExist.string))
                    }
                    return recipientFieldState.copy(\.recipients, to: newRecipients)
                }
            })
        )
    }

    private func updateStateAttachmentUIModels() async {
        do {
            let draftAttachments = try await draft.attachmentList().attachments().get()
            let dispositions = draftAttachments.map(\.attachment.disposition)
            let inlineCount = dispositions.filter { $0 == .inline }.count
            let attachmentCount = dispositions.filter { $0 == .attachment }.count
            AppLogger.log(message: "Attachments update: inline: \(inlineCount), attachment: \(attachmentCount)", category: .composer)
            state.attachments = draftAttachments.toDraftAttachmentUIModels()
            attachmentAlertState.enqueueAlertsForFailedAttachmentUploads(attachments: draftAttachments)
        } catch {
            AppLogger.log(error: error, category: .composer)
            showToast(.error(message: error.localizedDescription))
        }
    }

    private func reloadBody(clearImageCacheFirst: Bool) async {
        guard !messageHasBeenSentOrScheduled else { return }
        await updateBodyDebounceTask?.executeImmediately()
        bodyAction = .reloadBody(html: draft.body(), clearImageCacheFirst: clearImageCacheFirst)
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
            return addLastRecipientToState(for: group, in: recipientList)
        case .duplicate, .saveFailed, .other:
            restoreRecipientStateAfterError(for: group)
            showToast(.error(message: result.localizedErrorMessage(entry: entry), duration: .medium))
            return nil
        }
    }

    @discardableResult
    private func addContactGroupInRecipients(
        contactGroupName: String,
        recipients: [SingleRecipientEntry],
        total: UInt64,
        group: RecipientGroupType
    ) -> ComposerRecipient? {
        let recipientList = recipientList(from: draft, group: group)
        let result = recipientList.addGroupRecipient(groupName: contactGroupName, recipients: recipients, totalContactsInGroup: total)
        switch result {
        case .ok:
            return addLastRecipientToState(for: group, in: recipientList)
        case .duplicate, .saveFailed, .emptyGroupName, .other:
            restoreRecipientStateAfterError(for: group)
            if let message = result.localizedErrorMessage() {
                showToast(.error(message: message, duration: .medium))
            }
            return nil
        }
    }

    private func addLastRecipientToState(for group: RecipientGroupType, in recipientList: ComposerRecipientListProtocol) -> ComposerRecipient {
        let lastRecipient = recipientList.recipients().last!
        state.overrideRecipientState(for: group) { recipientFieldState in
            recipientFieldState.copy(
                \.recipients,
                to: recipientFieldState.recipients + [RecipientUIModel(composerRecipient: lastRecipient)]
            )
            .copy(\.input, to: .empty)
            .copy(\.controllerState, to: .editing)
        }
        return lastRecipient
    }

    private func restoreRecipientStateAfterError(for group: RecipientGroupType) {
        state.overrideRecipientState(for: group) { recipientFieldState in
            recipientFieldState.copy(\.input, to: .empty)
                .copy(\.controllerState, to: .editing)
        }
    }

    private func removeRecipients(for draft: AppDraftProtocol, group: RecipientGroupType, recipients uiModels: [RecipientUIModel]) {
        let recipientList = recipientList(from: draft, group: group)
        for uiModel in uiModels {
            let result: RemoveRecipientError
            switch uiModel.composerRecipient {
            case .single(let single):
                result = recipientList.removeSingleRecipient(email: single.address)
            case .group(let group):
                result = recipientList.removeGroup(groupName: group.displayName)
            }
            showToastIfError(result: result)
        }
        let uiModelsAfterRemove = recipientUIModels(from: draft, for: group)
        state.updateRecipientState(for: group) { $0.recipients = uiModelsAfterRemove }
    }

    private func showToastIfError(result: RemoveRecipientError) {
        switch result {
        case .ok:
            return
        case .emptyGroupName, .saveFailed, .other:
            AppLogger.log(message: "remove recipient error \(result)", category: .composer, isError: true)
            showToast(.error(message: result.localizedErrorMessage().string))
        }
    }

    private func endEditing(group: RecipientFieldState) -> RecipientFieldState {
        var newRecipients = group.recipients
        group.recipients.indices.forEach { newRecipients[$0].isSelected = false }
        return group.copy(\.recipients, to: newRecipients)
            .copy(\.input, to: .empty)
            .copy(\.controllerState, to: .collapsed)
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

    private func performSendOrSchedule(date: Date?) async -> VoidDraftSendResult {
        if let date {
            AppLogger.log(message: "scheduling message", category: .composer)
            return await draft.schedule(timestamp: UInt64(date.timeIntervalSince1970))
        } else {
            AppLogger.log(message: "sending message", category: .composer)
            return await draft.send()
        }
    }

    private func dismissReasonAfterSend(isScheduled: Bool) async -> ComposerDismissReason {
        await isScheduled ? .messageScheduled(messageId: draftMessageId()!) : .messageSent(messageId: draftMessageId()!)
    }

    private func debounce(_ block: @escaping () -> Void) {
        updateBodyDebounceTask?.cancel()
        updateBodyDebounceTask = DebouncedTask(duration: .seconds(2), block: block) { [weak self] in
            self?.updateBodyDebounceTask = nil
        }
        updateBodyDebounceTask?.debounce()
    }

    func showToast(_ toastToShow: Toast) {
        Dispatcher.dispatchOnMain(.init(block: { [weak self] in self?.toast = toastToShow }))
    }

    private func dismissComposer(dismissAction: Dismissable, reason: ComposerDismissReason) {
        composerWillDismiss = true
        dismissAction()
        onDismiss(reason)
    }
}
