//
//  MoveToActionSheetProtocol.swift
//  ProtonMail
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

import Foundation

protocol MoveToActionSheetProtocol: AnyObject {
    var user: UserManager { get }
    var labelId: String { get }
    var selectedMoveToFolder: MenuLabel? { get set }

    func handleMoveToAction(messages: [Message], isFromSwipeAction: Bool)
    func handleMoveToAction(conversations: [Conversation], isFromSwipeAction: Bool, completion: (() -> Void)?)
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
        let folders = (foldersController?.fetchedObjects as? [Label]) ?? []
        let datas: [MenuLabel] = Array(labels: folders, previousRawData: [])
        let (_, folderItems) = datas.sortoutData()
        return folderItems
    }

    func updateSelectedMoveToDestination(menuLabel: MenuLabel?, isOn: Bool) {
        selectedMoveToFolder = isOn ? menuLabel : nil
    }
}
