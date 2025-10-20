// Copyright (c) 2025 Proton Technologies AG
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

import proton_app_uniffi

extension MessageAction: DisplayableAction {

    var displayData: ActionDisplayData {
        switch self {
        case .markRead:
            Action.markAsRead.displayData
        case .markUnread:
            Action.markAsUnread.displayData
        case .star:
            Action.star.displayData
        case .unstar:
            Action.unstar.displayData
        case .labelAs:
            Action.labelAs.displayData
        case .moveTo:
            Action.moveTo.displayData
        case .moveToSystemFolder(let systemFolder):
            switch systemFolder.name {
            case .archive:
                Action.moveToArchive.displayData
            case .inbox:
                Action.moveToInbox.displayData
            case .spam:
                Action.moveToSpam.displayData
            case .trash:
                Action.moveToTrash.displayData
            }
        case .notSpam:
            Action.moveToInboxFromSpam.displayData
        case .permanentDelete:
            Action.deletePermanently.displayData
        case .reply:
            Action.reply.displayData
        case .replyAll:
            Action.replyAll.displayData
        case .forward:
            Action.forward.displayData
        case .print:
            Action.print.displayData
        case .viewHeaders:
            Action.viewHeaders.displayData
        case .viewHtml:
            Action.viewHTML.displayData
        case .viewInLightMode:
            Action.renderInLightMode.displayData
        case .viewInDarkMode:
            Action.renderInDarkMode.displayData
        case .reportPhishing:
            Action.reportPhishing.displayData
        case .more:
            InternalAction.more.displayData
        }
    }

    var isMoreAction: Bool {
        if case .more = self {
            true
        } else {
            false
        }
    }

}
