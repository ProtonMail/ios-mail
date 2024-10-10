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

import Foundation

class LabelAsSheetModel: ObservableObject {
    @Published var state: [LabelDisplayModel] = []

    func handle(action: LabelAsSheetAction) {
        switch action {
        case .loadData:
            loadLabels()
        case .selected(let label):
            updateSelection(of: label)
        }
    }

    private func loadLabels() {
        //
    }

    private func updateSelection(of selectedLabel: LabelDisplayModel) {
        state = state
            .map { label in
                label.copy(isSelected: updateSelectionIfNeeded(selectedLabel: selectedLabel, label: label))
            }
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
