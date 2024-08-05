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

protocol SelectableItem {
    associatedtype SelectableItemType

    var selectionIdentifier: String { get }
    func copy(isSelected: Bool) -> SelectableItemType
}

extension SidebarSystemFolderUIModel: SelectableItem {

    var selectionIdentifier: String {
        "\(identifier.rawValue)"
    }

    func copy(isSelected: Bool) -> Self {
        .init(
            isSelected: isSelected,
            localID: localID,
            identifier: identifier,
            unreadCount: unreadCount
        )
    }

}

extension SidebarOtherItemUIModel: SelectableItem {

    var selectionIdentifier: String {
        type.rawValue
    }

    func copy(isSelected: Bool) -> Self {
        .init(isSelected: isSelected, type: type, icon: icon, name: name)
    }

}
