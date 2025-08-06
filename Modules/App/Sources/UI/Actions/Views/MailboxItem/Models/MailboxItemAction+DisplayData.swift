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

extension MailboxItemAction {

    var displayData: ActionDisplayData {
        .init(title: correspondingAction.name, image: correspondingAction.icon)
    }

    private var correspondingAction: Action {
        switch self {
        case .star: .star
        case .unstar: .unstar
        case .pin: .pin
        case .unpin: .unpin
        case .labelAs: .labelAs
        case .markRead: .markAsRead
        case .markUnread: .markAsUnread
        case .delete: .deletePermanently
        case .snooze: .snooze
        }
    }

}
