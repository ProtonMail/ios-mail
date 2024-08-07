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

import DesignSystem
import proton_mail_uniffi
import SwiftUI

extension LocalLabel {

    func toLabelPickerCellUIModel(selectedIds: [PMLocalLabelId: Quantifier]) -> LabelPickerCellUIModel {
        let quantifier = selectedIds[id] ?? .none
        return LabelPickerCellUIModel(id: id, name: name, color: Color(hex: color), itemsWithLabel: quantifier)
    }
    
    /// - Parameter parentIds: collection of folder ids that have a subfolder
    func toFolderPickerCellUIModel(parentIds: Set<PMLocalLabelId>) -> FolderPickerCellUIModel {
        let icon: ImageResource
        if let systemFolderIcon = systemFolderIdentifier?.icon {
            icon = systemFolderIcon
        } else {
            icon = parentIds.contains(id) ? DS.Icon.icFolders : DS.Icon.icFolder
        }
        var level: UInt = 0
        if let numParentFolders = path?.components(separatedBy: "/").count {
            level = UInt(numParentFolders)
        }
        return FolderPickerCellUIModel(id: id, name: name, icon: icon, level: level)
    }
}
