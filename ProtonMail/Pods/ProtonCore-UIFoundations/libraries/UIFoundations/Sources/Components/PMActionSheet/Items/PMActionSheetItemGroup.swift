//
//  PMActionSheetItemGroup.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/18.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation

public struct PMActionSheetItemGroup {
    public let title: String?
    public let hasSeparator: Bool
    public internal(set) var items: [PMActionSheetItem]
    public let style: Style

    public init(title: String? = nil, items: [PMActionSheetItem], hasSeparator: Bool = true, style: Style) {
        self.title = title
        self.items = items
        self.hasSeparator = hasSeparator
        self.style = style
    }
}

extension PMActionSheetItemGroup {
    public enum Style: Equatable {
        /// Items will be laid out as grid cell style
        /// Components in item will be arrange vertically
        /// Int: how many columns in one row
        case grid(Int)
        /// Items in this style will be laid out as a list
        /// Components in item will be arrange horizontal
        case toggle
        /// Items will be laid out as a list
        /// Components in item will be arrange horizontal
        case clickable
        /// Items in this style will be laid out as a list
        /// the checkmark only be shown when the item is selected
        /// Components in item will be arrange horizontal
        case singleSelection
        /// Items in this style will be laid out as a list
        /// the checkmark only be shown when items are selected
        /// Components in item will be arrange horizontal
        case multiSelection
        /// Items in this style will be laid out as a list
        /// the checkmark icon is always displayed, the unselected item will be an empty hole
        /// Components in item will be arrange horizontal
        case singleSelectionNewStyle
        /// Items in this style will be laid out as a list
        /// the checkmark icon is always displayed, the unselected item will be an empty hole
        /// Components in item will be arrange horizontal
        case multiSelectionNewStyle
    }
}

#endif
