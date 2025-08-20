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

import proton_app_uniffi
import InboxDesignSystem
import SwiftUI

extension ListActions {

    var displayData: ActionDisplayData {
        switch self {
        case .labelAs:
            .init(title: L10n.Action.labelAs, imageResource: DS.Icon.icTag)
        case .markRead:
            .init(title: L10n.Action.markAsRead, imageResource: DS.Icon.icEnvelopeOpen)
        case .markUnread:
            .init(title: L10n.Action.markAsUnread, imageResource: DS.Icon.icEnvelopeDot)
        case .more:
            .init(title: .empty, imageResource: DS.Icon.icThreeDotsHorizontal)
        case .moveTo:
            .init(title: L10n.Action.moveTo, imageResource: DS.Icon.icFolderArrowIn)
        case .moveToSystemFolder(let systemFolder):
            switch systemFolder.name {
            case .archive:
                .init(title: L10n.Action.moveToArchive, imageResource: DS.Icon.icArchiveBox)
            case .inbox:
                .init(title: L10n.Action.moveToInbox, imageResource: DS.Icon.icInbox)
            case .spam:
                .init(title: L10n.Action.moveToSpam, imageResource: DS.Icon.icSpam)
            case .trash:
                .init(title: L10n.Action.moveToTrash, imageResource: DS.Icon.icTrash)
            }
        case .notSpam:
            .init(title: L10n.Action.notSpam, imageResource: DS.Icon.icNotSpam)
        case .permanentDelete:
            .init(title: L10n.Action.deletePermanently, imageResource: DS.Icon.icTrashCross)
        case .star:
            .init(title: L10n.Action.star, image: Image(symbol: .star))
        case .unstar:
            .init(title: L10n.Action.unstar, image: Image(symbol: .starSlash))
        case .snooze:
            .init(title: L10n.Action.snooze, imageResource: DS.Icon.icClock)
        }
    }

}

extension LocalizedStringResource {
    static var empty: Self {
        "".notLocalized.stringResource
    }
}
