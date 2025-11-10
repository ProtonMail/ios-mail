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
import proton_app_uniffi

struct MailboxItemsListViewConfiguration {
    /// State observed by the list to update the data.
    let dataSource: PaginatedListDataSource<MailboxItemCellUIModel>
    /// Item selection observed to manage the selection state.
    let selectionState: SelectionModeState
    /// Determines whether the actions are for messages or conversations
    let itemTypeForActionBar: MailboxItemType
    /// If this is a system label (e.g. Mailbox, All Mail), the label is set;
    /// otherwise (for example, a custom folder), it is `nil`.
    let systemLabel: SystemLabel?
    /// Swipe actions to be applied to the cells.
    var swipeActions: AssignedSwipeActions = .init(left: .noAction, right: .noAction)
    /// Listener for events related to the list.
    var listEventHandler: MailboxItemsListEventHandler?
    /// Listener for events related to the cells of the list.
    var cellEventHandler: MailboxItemsCellEventHandler?
}

extension MailboxItemsListViewConfiguration {
    /// Determines if it's Outbox location
    var isOutboxLocation: Bool {
        systemLabel == .outbox
    }

}

struct MailboxItemsListEventHandler {
    let listAtTop: ((Bool) -> Void)?
    let pullToRefresh: (() async -> Void)?
}

struct SwipeActionContext {
    let action: AssignedSwipeAction
    let itemID: ID
    let isItemRead: Bool
    let isItemStarred: Bool
}

struct MailboxItemsCellEventHandler {
    var onCellEvent: (MailboxItemCellEvent, MailboxItemCellUIModel) -> Void
    var onSwipeAction: ((SwipeActionContext) -> Void)?
}
