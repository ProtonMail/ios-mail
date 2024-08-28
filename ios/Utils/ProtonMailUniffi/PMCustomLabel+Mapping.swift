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

extension PMCustomLabel {

    // MARK: - UI

    func toLabelPickerCellUIModel(selectedIds: [Id: Quantifier]) -> LabelPickerCellUIModel {
        let quantifier = selectedIds[id] ?? .none

        return LabelPickerCellUIModel(
            id: id,
            name: name,
            color: Color(hex: color.value),
            itemsWithLabel: quantifier
        )
    }

}


extension PMCustomFolder {

    var childLevel: Int {
        guard let count = path?.components(separatedBy: "/").count else { return 0 }
        return count - 1
    }

}

extension PMCustomLabel {

    var sidebarLabel: SidebarLabel {
        .init(
            id: id,
            color: color.value,
            name: name,
            unreadCount: UnreadCountFormatter.string(count: unread),
            isSelected: false
        )
    }

}

extension PMSystemLabel {

    var sidebarSystemFolder: SystemFolder? {
        guard case .system(let systemFolder) = description, let systemFolder else {
            return nil
        }

        return .init(
            id: id,
            type: systemFolder,
            unreadCount: UnreadCountFormatter.string(count: unread),
            isSelected: false
        )
    }

}
