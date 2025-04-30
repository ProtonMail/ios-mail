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

extension BottomBarAction {

    var displayData: MailboxActionBarActionDisplayData {
        switch self {
        case .labelAs:
            return .init(icon: DS.Icon.icTag, name: L10n.Action.labelAs)
        case .markRead:
            return .init(icon: DS.Icon.icEnvelopeOpen, name: L10n.Action.markAsRead)
        case .markUnread:
            return .init(icon: DS.Icon.icEnvelopeDot, name: L10n.Action.markAsUnread)
        case .more:
            return .init(icon: DS.Icon.icThreeDotsHorizontal, name: nil)
        case .moveTo:
            return .init(icon: DS.Icon.icFolderArrowIn, name: L10n.Action.moveTo)
        case .moveToSystemFolder(let systemFolder):
            switch systemFolder.name {
            case .archive:
                return .init(icon: DS.Icon.icArchiveBox, name: L10n.Action.moveToArchive)
            case .inbox:
                return .init(icon: DS.Icon.icInbox, name: L10n.Action.moveToInbox)
            case .spam:
                return .init(icon: DS.Icon.icSpam, name: L10n.Action.moveToSpam)
            case .trash:
                return .init(icon: DS.Icon.icTrash, name: L10n.Action.moveToTrash)
            }
        case .notSpam:
            return .init(icon: DS.Icon.icNotSpam, name: L10n.Action.notSpam)
        case .permanentDelete:
            return .init(icon: DS.Icon.icTrashCross, name: L10n.Action.deletePermanently)
        case .star:
            return .init(icon: DS.Icon.icStar, name: L10n.Action.star)
        case .unstar:
            return .init(icon: DS.Icon.icStarSlash, name: L10n.Action.unstar)
        }
    }

}
