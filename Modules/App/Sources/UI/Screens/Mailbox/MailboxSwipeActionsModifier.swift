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
import SwiftUI

struct MailboxSwipeActionsModifier: ViewModifier {
    typealias OnTapAction = (SwipeActionContext) -> Void

    @State private(set) var triggerFeedback = false
    private let mailboxItemId: ID
    private let isItemRead: Bool
    private let isItemStarred: Bool
    private let onTap: OnTapAction

    private let swipeActions: AssignedSwipeActions

    init(
        swipeActions: AssignedSwipeActions,
        mailboxItemId: ID,
        isItemRead: Bool,
        isItemStarred: Bool,
        onTapAction: @escaping OnTapAction
    ) {
        self.mailboxItemId = mailboxItemId
        self.isItemRead = isItemRead
        self.isItemStarred = isItemStarred
        self.swipeActions = swipeActions
        self.onTap = onTapAction
    }

    func body(content: Content) -> some View {
        content
            .if(swipeActions.right != .noAction) { view in
                view.swipeActions(edge: .leading) {
                    button(for: swipeActions.right)
                }
            }
            .if(swipeActions.left != .noAction) { view in
                view.swipeActions(edge: .trailing) {
                    button(for: swipeActions.left)
                }
            }
    }

    @ViewBuilder
    private func button(for action: AssignedSwipeAction) -> some View {
        VStack {
            Button(role: .cancel) {
                onTap(.init(action: action, itemID: mailboxItemId, isItemRead: isItemRead, isItemStarred: isItemStarred))
                triggerFeedback.toggle()
            } label: {
                action.icon(isRead: isItemRead, isStarred: isItemStarred)
            }
        }
        .tint(action.color)
        .sensoryFeedback(.success, trigger: triggerFeedback)
    }
}

extension View {

    @ViewBuilder
    func mailboxSwipeActions(
        swipeActions: AssignedSwipeActions,
        isSwipeEnabled: Bool,
        mailboxItem: MailboxItemCellUIModel,
        onTapAction: @escaping MailboxSwipeActionsModifier.OnTapAction
    ) -> some View {
        if isSwipeEnabled, [swipeActions.left, swipeActions.right].contains(where: { $0 != .noAction }) {
            self.modifier(
                MailboxSwipeActionsModifier(
                    swipeActions: swipeActions,
                    mailboxItemId: mailboxItem.id,
                    isItemRead: mailboxItem.isRead,
                    isItemStarred: mailboxItem.isStarred,
                    onTapAction: onTapAction
                )
            )
        } else {
            self
        }
    }
}
