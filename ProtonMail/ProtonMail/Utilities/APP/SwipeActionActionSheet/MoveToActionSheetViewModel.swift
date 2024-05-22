//
//  MoveToActionSheetViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreUIFoundations
import UIKit

protocol MoveToActionSheetViewModel {
    var menuLabels: [MenuLabel] { get }
    var isEnableColor: Bool { get }
    var isInherit: Bool { get }
    func getColor(of label: MenuLabel) -> UIColor
}

extension MoveToActionSheetViewModel {
    func getColor(of label: MenuLabel) -> UIColor {
        guard label.location.icon == nil else {
            return ColorProvider.IconNorm
        }

        guard isEnableColor else { return ColorProvider.IconNorm }
        if isInherit {
            guard let parent = menuLabels.getRootItem(of: label),
                  let parentColor = parent.iconColor else {
                return ColorProvider.IconNorm
            }
            return UIColor(hexColorCode: parentColor)
        } else if let labelColor = label.iconColor {
            return UIColor(hexColorCode: labelColor)
        } else {
            return ColorProvider.IconNorm
        }
    }
}

struct MoveToActionSheetViewModelMessages: MoveToActionSheetViewModel {
    let menuLabels: [MenuLabel]
    let isEnableColor: Bool
    let isInherit: Bool

    init(menuLabels: [MenuLabel],
         isEnableColor: Bool,
         isInherit: Bool) {
        self.isInherit = isInherit
        self.isEnableColor = isEnableColor
        self.menuLabels = menuLabels
    }
}

struct MoveToActionSheetViewModelConversations: MoveToActionSheetViewModel {
    let menuLabels: [MenuLabel]
    let isEnableColor: Bool
    let isInherit: Bool

    init(menuLabels: [MenuLabel],
         isEnableColor: Bool,
         isInherit: Bool) {
        self.isInherit = isInherit
        self.isEnableColor = isEnableColor
        self.menuLabels = menuLabels
    }
}
