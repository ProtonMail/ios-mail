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

/**
 List of actions that  can change, depending on some conditions of the object receiving the action.
 */
enum ConditionalAction {
    case toggleReadStatus
    case toggleStarStatus
    case moveToTrash
    case moveToArchive
    // use this instead of moveToArchive if you need to show moveToInbox in the trash folder as well
    case moveToArchiveWithTrashFolderCondition

    func toAction(params: ConditionalActionResolverParams) -> Action {
        switch self {
        case .moveToTrash:
            return params.systemFolder != .trash ? Action.moveToTrash : Action.deletePermanently
        case .moveToArchive:
            return params.systemFolder != .archive ? Action.moveToArchive : Action.moveToInbox
        case .moveToArchiveWithTrashFolderCondition:
            if params.systemFolder == .trash {
                return Action.moveToInbox
            }
            return ConditionalAction.moveToArchive.toAction(params: params)
        case .toggleReadStatus:
            return Action.toggleReadStatusAction(when: params.selectionReadStatus)
        case .toggleStarStatus:
            return Action.toggleStarStatusAction(when: params.selectionStarStatus)
        }
    }
}
