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

extension MailboxItemAction_v2 {

    var displayData: ActionDisplayData {
        switch self {
        case .star:
            .init(title: L10n.Action.star, image: DS.Icon.icStar)
        case .unstar:
            .init(title: L10n.Action.unstar, image: DS.Icon.icStarSlash)
        case .pin:
            .init(title: L10n.Action.pin, image: DS.Icon.icPinAngled)
        case .unpin:
            .init(title: L10n.Action.unpin, image: DS.Icon.icPinAngledSlash)
        case .labelAs:
            .init(title: L10n.Action.labelAs, image: DS.Icon.icTag)
        case .markRead:
            .init(title: L10n.Action.markAsRead, image: DS.Icon.icEnvelopeDot)
        case .markUnread:
            .init(title: L10n.Action.markAsUnread, image: DS.Icon.icEnvelopeOpen)
        case .delete:
            .init(title: L10n.Action.deletePermanently, image: DS.Icon.icTrash)
        }
    }

}
