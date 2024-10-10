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

extension MoveToAction {

    var displayData: ActionDisplayData {
        switch self {
        case .system(let systemFolder):
            switch systemFolder.systemLabel {
            case .inbox:
                .init(title: L10n.Mailbox.SystemFolder.inbox, image: DS.Icon.icInbox)
            case .archive:
                .init(title: L10n.Mailbox.SystemFolder.archive, image: DS.Icon.icArchiveBox)
            case .spam:
                .init(title: L10n.Mailbox.SystemFolder.spam, image: DS.Icon.icFire)
            case .trash:
                .init(title: L10n.Mailbox.SystemFolder.trash, image: DS.Icon.icTrash)
            }
        case .moveTo:
            .init(title: L10n.Action.moveTo, image: DS.Icon.icFolderArrowIn)
        }
    }

}
