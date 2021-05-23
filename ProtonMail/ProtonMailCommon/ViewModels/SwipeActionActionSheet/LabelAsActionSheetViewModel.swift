//
//  LabelAsActionSheetViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

struct LabelAsActionSheetViewModel {
    let menuLabels: [MenuLabel]
    private var initialLabelSelectionCount: [MenuLabel: Int] = [:]
    private(set) var initialLabelSelectionStatus: [MenuLabel: PMActionSheetPlainItem.MarkType] = [:]

    init(menuLabels: [MenuLabel], messages: [Message]) {
        self.menuLabels = menuLabels
        menuLabels.forEach { initialLabelSelectionCount[$0] = 0 }
        initialLabelSelectionCount.forEach { (label, _) in
            for msg in messages where msg.contains(label: label.location.labelID) {
                if let labelCount = initialLabelSelectionCount[label] {
                    initialLabelSelectionCount[label] = labelCount + 1
                } else {
                    initialLabelSelectionCount[label] = 1
                }
            }
        }

        initialLabelSelectionCount.forEach { (key, value) in
            if value == messages.count {
                initialLabelSelectionStatus[key] = .checkMark
            } else if value < messages.count && value > 0 {
                initialLabelSelectionStatus[key] = .dash
            } else {
                initialLabelSelectionStatus[key] = PMActionSheetPlainItem.MarkType.none
            }
        }
    }

    func getColor(of label: MenuLabel) -> UIColor {
        return UIColor(hexColorCode: label.iconColor)
    }
}
