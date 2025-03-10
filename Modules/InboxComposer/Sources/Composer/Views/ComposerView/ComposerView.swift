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

    init(
        draft: AppDraftProtocol,
        draftOrigin: DraftOrigin,
        draftSavedToastCoordinator: DraftSavedToastCoordinator,
        contactProvider: ComposerContactProvider,
        photosItemsHandler: PhotosPickerItemHandler,
        cameraImageHandler: CameraImageHandler,
        fileItemsHandler: FilePickerItemHandler,
        onSendingEvent: @escaping () -> Void
    ) {
        self._model = StateObject(
            wrappedValue: ComposerModel(
                draft: draft,
                draftOrigin: draftOrigin,
                draftSavedToastCoordinator: draftSavedToastCoordinator,
                contactProvider: contactProvider,
                onSendingEvent: onSendingEvent,
                permissionsHandler: CNContactStore.self,
                contactStore: CNContactStore(),
                photosItemsHandler: photosItemsHandler,
                cameraImageHandler: cameraImageHandler,
                fileItemsHandler: fileItemsHandler
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ComposerTopBar(
                isSendEnabled: model.state.isSendAvailable,
                sendAction: { model.sendMessage(dismissAction: dismiss) },
                dismissAction: { dismiss() }
            )

            ComposerControllerRepresentable(state: model.state, embeddedImageProvider: model.embeddedImageProvider) { event in
                switch event {
                case .viewDidDisappear:
                    model.viewDidDisappear()

                case let .recipientFieldEvent(recipientFieldEvent, group):
                    switch recipientFieldEvent {
                    case .onFieldTap:
                        model.startEditingRecipients(for: group)
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onRecipientSelected(let index):
                        model.recipientToggleSelection(group: group, index: index)
                    case .onReturnKeyPressed(let text):
                        model.addRecipient(group: group, address: text)
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
                    case .onRemove:
                        toastStateStore.present(toast: .comingSoon)
                    }

                case .bodyEvent(let event):
                    switch event {
                    case .onStartEditing:
                        model.endEditingRecipients()
                    case .onBodyChange(let body):
                        model.updateBody(value: body)
                    }

                case .actionBarEvent(let event):
                    switch event {
                    case .onPickAttachmentSource:
                        model.pickAttachmentSource()
                    case .onDiscardDraft:
                        toastStateStore.present(toast: .comingSoon)
                    }
                }
            }
            .attachmentSourcePicker(isPresented: $model.pickersState.isAttachmentSourcePickerPresented) { selection in
                model.selectedAttachmentSource(selection)
            }
            .photosPicker(isPresented: $model.pickersState.isPhotosPickerPresented, selection: $selectedPhotosItems)
            .camera(isPresented: $model.pickersState.isCameraPresented, onPhotoTaken: model.addAttachments(image:))
            .fileImporter(isPresented: $model.pickersState.isFileImporterPresented, onCompletion: model.addAttachments(filePickerResult:))
            .onChange(of: selectedPhotosItems, { model.addAttachments(selectedPhotosItems: $selectedPhotosItems) })
            .onChange(of: model.toast) { _, newValue in
                guard let newValue else { return }
                toastStateStore.present(toast: newValue)
                model.toast = nil
            }
            .onLoad {
                Task {
                    await model.onLoad()
                }
            }

            Spacer()
        }
        .background(DS.Color.Background.norm)
    }
}
