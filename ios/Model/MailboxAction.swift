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
import class UIKit.UIImage

enum MailboxAction {
    case labelAs
    case moveTo
    case moveToSpam
    case moveToTrash
    case moveToArchive
    case snooze
    case toggleReadStatus
    case toggleStarStatus
}

extension MailboxAction {

    func toAction(
        selectionReadStatus: SelectionReadStatus,
        selectionStarStatus: SelectionStarStatus,
        systemFolder: SystemFolderIdentifier
    ) -> Action {
        switch self {
        case .labelAs:
            return .labelAs
        case .moveTo:
            return .moveTo
        case .moveToSpam:
            return .moveToSpam
        case .moveToTrash:
            return systemFolder == .trash ? Action.delete : Action.moveToTrash
        case .moveToArchive:
            return systemFolder == .archive ? Action.moveToInbox : Action.moveToArchive
        case .snooze:
            return .snooze
        case .toggleReadStatus:
            return Action.toggleReadStatusAction(when: selectionReadStatus)
        case .toggleStarStatus:
            return Action.toggleStarStatusAction(when: selectionStarStatus)
        }
    }
}
