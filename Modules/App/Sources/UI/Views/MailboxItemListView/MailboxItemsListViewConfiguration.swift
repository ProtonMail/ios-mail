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

struct MailboxItemsListViewConfiguration {
    /// State observed by the list to update the data.
    let dataSource: PaginatedListDataSource<MailboxItemCellUIModel>
    /// Item selection observed to manage the selection state.
    let selectionState: SelectionModeState
    /// Determines whether the actions are for messages or conversations
    let itemTypeForActionBar: MailboxItemType
    /// Swipe actions to be applied to the cells. If  `nil` no actions are configured.
    var swipeActions: MailboxItemsListSwipeActions?
    /// Listener for events related to the list.
    var listEventHandler: MailboxItemsListEventHandler?
    /// Listener for events related to the cells of the list.
    var cellEventHandler: MailboxItemsCellEventHandler?
}

struct MailboxItemsListActionBar {
    let selectedMailbox: SelectedMailbox
    let customLabelModel: CustomLabelModel
}

struct MailboxItemsListSwipeActions {
    let leadingSwipe: () -> SwipeAction
    let trailingSwipe: () -> SwipeAction
}

struct MailboxItemsListEventHandler {
    let listAtTop: ((Bool) -> Void)?
    let pullToRefresh: (() async -> Void)?
}

struct MailboxItemsCellEventHandler {
    var onCellEvent: (MailboxItemCellEvent, MailboxItemCellUIModel) -> Void
    var onSwipeAction: ((Action, ID) -> Void)?
}
