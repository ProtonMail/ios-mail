//
//  LabelAsActionSheetProtocol.swift
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

protocol LabelAsActionSheetProtocol: AnyObject {
    var user: UserManager { get }
    var labelId: String { get }
    var selectedLabelAsLabels: Set<LabelLocation> { get set }

    func handleLabelAsAction(messages: [Message], shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType])
    func handleLabelAsAction(conversations: [Conversation],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType],
                             completion: (() -> Void)?)
    func updateSelectedLabelAsDestination(menuLabel: MenuLabel?, isOn: Bool)
}

extension LabelAsActionSheetProtocol {
    func getLabelMenuItems() -> [MenuLabel] {
        let foldersController = user.labelService.fetchedResultsController(.label)
        try? foldersController?.performFetch()
        let folders = (foldersController?.fetchedObjects as? [Label]) ?? []
        let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
        let (labelItems, _) = datas.sortoutData()
        return labelItems
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
