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
import InboxDesignSystem
import PhotosUI
import SwiftUI

struct ComposerView: View {
    @Environment(\.dismissTestable) var dismiss: Dismissable
    @EnvironmentObject var toastStateStore: ToastStateStore
    @StateObject private var model: ComposerModel
    @State var selectedPhotosItems: [PhotosPickerItem] = []
    @State var modalState: ComposerViewModalState?
    @State var attachmentPickerState: AttachmentPickersState = .init()

    init(
        draft: AppDraftProtocol,
        draftOrigin: DraftOrigin,
        draftSavedToastCoordinator: DraftSavedToastCoordinator,
        contactProvider: ComposerContactProvider,
        onSendingEvent: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._model = StateObject(
            wrappedValue: ComposerModel(
                draft: draft,
                draftOrigin: draftOrigin,
                draftSavedToastCoordinator: draftSavedToastCoordinator,
                contactProvider: contactProvider,
                onSendingEvent: onSendingEvent,
                onCancel: onCancel,
                permissionsHandler: CNContactStore.self,
                contactStore: CNContactStore(),
                photosItemsHandler: .init(),
                cameraImageHandler: .init(),
                fileItemsHandler: .init()
            )
        )
    }

    var body: some View {
        let modalFactory = ComposerViewModalFactory(pickerState: $attachmentPickerState)

        VStack(spacing: 0) {
            ComposerTopBar(
                isSendEnabled: model.state.isSendAvailable,
                scheduleSendAction: { modalState = .scheduleSend },
                sendAction: { model.sendMessage(dismissAction: dismiss) },
                dismissAction: { model.dismissComposer(dismissAction: dismiss) }
            )

            ComposerControllerRepresentable(
                state: model.state,
                bodyAction: $model.bodyAction,
                embeddedImageProvider: model.embeddedImageProvider,
                invalidAddressAlertStore: model.invalidAddressAlertStore
            ) { event in
                switch event {
                case .viewDidDisappear:
                    Task { await model.viewDidDisappear() }

                case let .recipientFieldEvent(recipientFieldEvent, group):
                    switch recipientFieldEvent {
                    case .onFieldTap:
                        model.startEditingRecipients(for: group)
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onRecipientSelected(let index):
                        model.recipientToggleSelection(group: group, index: index)
                    case .onReturnKeyPressed:
                        model.addRecipientFromInput()
                    case .onDeleteKeyPressedInsideEmptyInputField:
                        model.selectLastRecipient(group: group)
                    case .onDeleteKeyPressedOutsideInputField:
                        model.removeRecipientsThatAreSelected(group: group)
                    }

                case let .contactPickerEvent(event, group):
                    switch event {
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onContactSelected(let contact):
                        model.addContact(group: group, contact: contact)
                    }

                case .fromFieldEvent(let event):
                    switch event {
                    case .onFieldTap:
                        toastStateStore.present(toast: .comingSoon)
                    }

                case .subjectFieldEvent(let event):
                    switch event {
                    case .onStartEditing:
                        model.endEditingRecipients()
                    case .onSubjectChange(let subject):
                        model.updateSubject(value: subject)
                    }

                case .attachmentEvent(let event):
                    switch event {
                    case .onRetryAttachmentUpload(let uiModel):
                        model.retryUploadingAttachment(uiModel: uiModel)
                    case .onTap:
                        toastStateStore.present(toast: .comingSoon)
                    case .onRemove(let uiModel):
                        model.removeAttachment(id: uiModel.attachment.id)
                    }

                case .bodyEvent(let event):
                    switch event {
                    case .onStartEditing:
                        model.endEditingRecipients()
                    case .onBodyChange(let body):
                        model.updateBody(value: body)
                    case .onImagePasted(let image):
                        Task { await model.addAttachments(image: image) }
                    case .onInlineImageRemoved(let cid), .onInlineImageRemovalRequested(let cid):
                        Task { await model.removeAttachment(cid: cid) }
                    case .onInlineImageDispositionChangeRequested:
                        toastStateStore.present(toast: .comingSoon)
                    }

                case .actionBarEvent(let event):
                    switch event {
                    case .onPickAttachmentSource:
                        modalState = .attachmentPicker
                    case .onDiscardDraft:
                        toastStateStore.present(toast: .comingSoon)
                    }
                }
            }
            .alert(
                Text(model.attachmentAlertState.presentedError?.title ?? LocalizedStringResource(stringLiteral: .empty)),
                isPresented: $model.attachmentAlertState.isAlertPresented,
                presenting: model.attachmentAlertState.presentedError,
                actions: { actionsForAttachmentAlert(error: $0) },
                message: { Text($0.message) }
            )
            .alert(model: model.alertBinding)
            .photosPicker(isPresented: $attachmentPickerState.isPhotosPickerPresented, selection: $selectedPhotosItems, preferredItemEncoding: .current)
            .camera(isPresented: $attachmentPickerState.isCameraPresented, onPhotoTaken: model.addAttachments(image:))
            .fileImporter(isPresented: $attachmentPickerState.isFileImporterPresented, onCompletion: model.addAttachments(filePickerResult:))
            .onChange(of: selectedPhotosItems) {
                Task {
                    let photos = $selectedPhotosItems.wrappedValue
                    $selectedPhotosItems.wrappedValue = []
                    await model.addAttachments(selectedPhotosItems: photos)
                }
            }
            .sheet(item: $modalState, content: modalFactory.makeModal(for:))
            .onChange(of: model.toast) { _, newValue in
                guard let newValue else { return }
                toastStateStore.present(toast: newValue)
                model.toast = nil
            }
            .onLoad {
                Task { await model.onLoad() }
            }

            Spacer()
        }
        .background(DS.Color.Background.norm)
    }

    @ViewBuilder
    private func actionsForAttachmentAlert(error: AttachmentErrorAlertModel) -> some View {
        ForEach(error.actions) { action in
            Button(role: .cancel) {
                if action.removeAttachment {
                    model.removeAttachments(for: error)
                }
                model.attachmentAlertState.errorDismissedShowNextError()
            } label: {
                Text(action.title)
            }
        }
    }
}
