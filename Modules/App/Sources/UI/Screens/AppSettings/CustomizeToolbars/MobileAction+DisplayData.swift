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

extension MobileAction {

    var displayData: ActionDisplayData {
        action.displayData
    }

    private var action: Action {
        switch self {
        case .archive:
            Action.moveToArchive
        case .forward:
            Action.forward
        case .label:
            Action.labelAs
        case .move:
            Action.moveTo
        case .print:
            Action.print
        case .reply:
            Action.reply
        case .reportPhishing:
            Action.reportPhishing
        case .snooze:
            Action.snooze
        case .spam:
            Action.moveToSpam
        case .toggleLight:
            Action.renderInLightMode
        case .toggleRead:
            Action.markAsUnread
        case .toggleStar:
            Action.star
        case .trash:
            Action.moveToTrash
        case .viewHeaders:
            Action.viewHeaders
        case .viewHtml:
            Action.viewHTML
        }
    }

}
