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

import InboxDesignSystem
import SwiftUI

extension BottomBarAction {

    var displayData: MailboxActionBarActionDisplayData {
        switch self {
        case .labelAs:
            .init(imageResource: DS.Icon.icTag, name: L10n.Action.labelAs)
        case .markRead:
            .init(imageResource: DS.Icon.icEnvelopeOpen, name: L10n.Action.markAsRead)
        case .markUnread:
            .init(imageResource: DS.Icon.icEnvelopeDot, name: L10n.Action.markAsUnread)
        case .more:
            .init(imageResource: DS.Icon.icThreeDotsHorizontal, name: nil)
        case .moveTo:
            .init(imageResource: DS.Icon.icFolderArrowIn, name: L10n.Action.moveTo)
        case .moveToSystemFolder(let systemFolder):
            switch systemFolder.name {
            case .archive:
                .init(imageResource: DS.Icon.icArchiveBox, name: L10n.Action.moveToArchive)
            case .inbox:
                .init(imageResource: DS.Icon.icInbox, name: L10n.Action.moveToInbox)
            case .spam:
                .init(imageResource: DS.Icon.icSpam, name: L10n.Action.moveToSpam)
            case .trash:
                .init(imageResource: DS.Icon.icTrash, name: L10n.Action.moveToTrash)
            }
        case .notSpam:
            .init(imageResource: DS.Icon.icNotSpam, name: L10n.Action.notSpam)
        case .permanentDelete:
            .init(imageResource: DS.Icon.icTrashCross, name: L10n.Action.deletePermanently)
        case .star:
            .init(icon: Image(symbol: .star), name: L10n.Action.star)
        case .unstar:
            .init(icon: Image(symbol: .starSlash), name: L10n.Action.unstar)
        case .snooze:
            .init(imageResource: DS.Icon.icClock, name: L10n.Action.snooze)
        }
    }

}

private extension MailboxActionBarActionDisplayData {

    init(imageResource: ImageResource, name: LocalizedStringResource?) {
        self.init(icon: Image(imageResource), name: name)
    }

}
