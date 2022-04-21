//
//  MoveToActionSheetProtocol.swift
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

import Foundation

protocol MoveToActionSheetProtocol: AnyObject {
    var user: UserManager { get }
    var labelId: LabelID { get }
    var selectedMoveToFolder: MenuLabel? { get set }

    func handleMoveToAction(messages: [MessageEntity], isFromSwipeAction: Bool)
    func handleMoveToAction(conversations: [ConversationEntity], isFromSwipeAction: Bool, completion: (() -> Void)?)
    func updateSelectedMoveToDestination(menuLabel: MenuLabel?, isOn: Bool)
}

extension MoveToActionSheetProtocol {
    func getFolderMenuItems() -> [MenuLabel] {
        return getCustomFolderMenuItems() + getMailBoxMenuItems()
    }

    func getMailBoxMenuItems() -> [MenuLabel] {
        let items = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash)
        ]
        return items
    }

    func getCustomFolderMenuItems() -> [MenuLabel] {
        let foldersController = user.labelService.fetchedResultsController(.folderWithInbox)
        try? foldersController?.performFetch()
        let folders = (foldersController?.fetchedObjects as? [Label])?.compactMap({ LabelEntity(label: $0) }) ?? []
        let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return folderItems
    }

    func updateSelectedMoveToDestination(menuLabel: MenuLabel?, isOn: Bool) {
        selectedMoveToFolder = isOn ? menuLabel : nil
    }
}
