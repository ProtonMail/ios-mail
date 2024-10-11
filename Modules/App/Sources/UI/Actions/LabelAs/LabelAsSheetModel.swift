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
import proton_app_uniffi

class LabelAsSheetModel: ObservableObject {
    @Published var state: LabelAsSheetState = .initial
    private let input: LabelAsActionSheetInput
    private let actionsProvider: LabelAsActionsProvider

    init(input: LabelAsActionSheetInput, mailbox: Mailbox, actionsProvider: LabelAsAvailableActionsProvider) {
        self.input = input
        self.actionsProvider = .init(mailbox: mailbox, labelAsAvailableActionsProvider: actionsProvider)
    }

    func loadLabels() async {
        switch await actionsProvider.actions(for: input.type, ids: input.ids) {
        case .success(let labels):
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.update(labels: labels)
            }))
        case .failure:
            fatalError("Handle error here")
        }
    }

    func handle(action: LabelAsSheetAction) {
        switch action {
        case .selected(let label):
            updateSelection(of: label)
        case .toggleSwitch:
            state = state.copy(shouldArchive: state.shouldArchive.toggled)
        }
    }

    // MARK: - Private

    private func update(labels: [LabelAsAction]) {
        state = state.copy(labels: labels.map(\.displayModel))
    }

    private func updateSelection(of selectedLabel: LabelDisplayModel) {
        let updatedLabels = state.labels
            .map { label in
                label.copy(isSelected: updateSelectionIfNeeded(selectedLabel: selectedLabel, label: label))
            }
        state = state.copy(labels: updatedLabels)
    }

    private func updateSelectionIfNeeded(selectedLabel: LabelDisplayModel, label: LabelDisplayModel) -> IsSelected {
        guard selectedLabel.id == label.id else { return label.isSelected }
        return [IsSelected.partial, .selected].contains(selectedLabel.isSelected) ? .unselected : .selected
    }
}

private extension LabelDisplayModel {
    func copy(isSelected: IsSelected) -> Self {
        .init(id: id, hexColor: hexColor, title: title, isSelected: isSelected)
    }
}

private extension LabelAsSheetState {
    static let initial = LabelAsSheetState(labels: [], shouldArchive: false)

    func copy(shouldArchive: Bool) -> Self {
        .init(labels: labels, shouldArchive: shouldArchive)
    }

    func copy(labels: [LabelDisplayModel]) -> Self {
        .init(labels: labels, shouldArchive: shouldArchive)
    }
}

private extension Bool {
    var toggled: Bool {
        !self
    }
}

extension LabelAsAction {

    var displayModel: LabelDisplayModel {
        .init(id: labelId, hexColor: color.value, title: name, isSelected: isSelected)
    }

}
