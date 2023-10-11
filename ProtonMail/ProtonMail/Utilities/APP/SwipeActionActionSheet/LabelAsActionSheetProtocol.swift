//
//  LabelAsActionSheetProtocol.swift
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

protocol LabelAsActionSheetProtocol: AnyObject {
    var user: UserManager { get }
    var selectedLabelAsLabels: Set<LabelLocation> { get set }

    func handleLabelAsAction(messages: [MessageEntity], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType])
    func handleLabelAsAction(conversations: [ConversationEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetItem.MarkType],
                             completion: (() -> Void)?)
    func updateSelectedLabelAsDestination(menuLabel: MenuLabel?, isOn: Bool)
}

extension LabelAsActionSheetProtocol {
    func getLabelMenuItems() -> [MenuLabel] {
        do {
            let folders = try user.labelService.fetchLabels(type: .label)
            let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
            let (labelItems, _) = datas.sortoutData()
            return labelItems
        } catch {
            PMAssertionFailure(error)
            return []
        }
    }

    func updateSelectedLabelAsDestination(menuLabel: MenuLabel?, isOn: Bool) {
        if let label = menuLabel {
            if isOn {
                selectedLabelAsLabels.insert(label.location)
            } else {
                selectedLabelAsLabels.remove(label.location)
            }
        } else {
            selectedLabelAsLabels.removeAll()
        }
    }
}
