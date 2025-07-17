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

import Combine
import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

class LabelAsSheetModel: ObservableObject {
    @Published var state: LabelAsSheetState = .initial
    private let input: ActionSheetInput
    private let actionsProvider: LabelAsActionsProvider
    private let labelAsActionPerformer: LabelAsActionPerformer
    private let toastStateStore: ToastStateStore
    private let dismiss: () -> Void

    init(
        input: ActionSheetInput,
        mailbox: Mailbox,
        availableLabelAsActions: AvailableLabelAsActions,
        labelAsActions: LabelAsActions,
        toastStateStore: ToastStateStore,
        dismiss: @escaping () -> Void
    ) {
        self.input = input
        self.actionsProvider = .init(mailbox: mailbox, availableLabelAsActions: availableLabelAsActions)
        self.labelAsActionPerformer = .init(mailbox: mailbox, labelAsActions: labelAsActions)
        self.toastStateStore = toastStateStore
        self.dismiss = dismiss
    }

    func handle(action: LabelAsSheetAction) {
        switch action {
        case .viewAppear:
            loadLabels()
        case .selected(let label):
            updateSelection(of: label)
        case .toggleSwitch:
            state = state.copy(\.shouldArchive, to: state.shouldArchive.toggled)
        case .createLabelButtonTapped:
            state = state.copy(\.createFolderLabelPresented, to: true)
        case .doneButtonTapped:
            executeLabelAsAction()
        }
    }

    // MARK: - Private

    private func loadLabels() {
        Task {
            do {
                let labels = try await actionsProvider.actions(for: input.type.inboxItemType, ids: input.ids)
                Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                    self?.update(labels: labels)
                }))
            } catch {
                showError(error)
            }
        }
    }

    private func executeLabelAsAction() {
        Task {
            do {
                try await labelAsActionPerformer.labelAs(
                    input: .init(
                        itemType: input.type.inboxItemType,
                        itemsIDs: input.ids,
                        selectedLabelsIDs: state.labels.filter { $0.isSelected == .selected }.map(\.id),
                        partiallySelectedLabelsIDs: state.labels.filter { $0.isSelected == .partial }.map(\.id),
                        archive: state.shouldArchive
                    ))
            } catch {
                showError(error)
            }

            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.dismiss()
                }))
        }
    }

    private func update(labels: [LabelAsAction]) {
        state = state.copy(\.labels, to: labels.map(\.displayModel))
    }

    private func updateSelection(of selectedLabel: LabelDisplayModel) {
        let updatedLabels = state.labels
            .map { label in
                label.copy(\.isSelected, to: updateSelectionIfNeeded(selectedLabel: selectedLabel, label: label))
            }
        state = state.copy(\.labels, to: updatedLabels)
    }

    private func updateSelectionIfNeeded(selectedLabel: LabelDisplayModel, label: LabelDisplayModel) -> IsSelected {
        guard selectedLabel.id == label.id else { return label.isSelected }
        return [IsSelected.partial, .selected].contains(selectedLabel.isSelected) ? .unselected : .selected
    }

    private func showError(_ error: Error) {
        Dispatcher.dispatchOnMain(.init { [weak self] in
            self?.toastStateStore.present(toast: .error(message: error.localizedDescription))
        })
    }
}

private extension Bool {
    var toggled: Bool {
        !self
    }
}

private extension LabelAsSheetState {
    static let initial = LabelAsSheetState(labels: [], shouldArchive: false, createFolderLabelPresented: false)
}

extension LabelAsAction {

    var displayModel: LabelDisplayModel {
        .init(id: labelId, color: Color(hex: color.value), title: name, isSelected: isSelected)
    }

}
