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

import SwiftUI

struct MailboxSwipeActionsModifier: ViewModifier {
    typealias OnTapAction = (Action, ID) -> Void

    @State private(set) var triggerFeedback = false
    private let mailboxItemId: ID
    private let isItemRead: Bool
    private let onTap: OnTapAction

    private let leadingSwipe: SwipeAction
    private let trailingSwipe: SwipeAction

    init(
        leadingSwipe: SwipeAction,
        trailingSwipe: SwipeAction,
        mailboxItemId: ID,
        isItemRead: Bool,
        onTapAction: @escaping OnTapAction
    ) {
        self.mailboxItemId = mailboxItemId
        self.isItemRead = isItemRead
        self.leadingSwipe = leadingSwipe
        self.trailingSwipe = trailingSwipe
        self.onTap = onTapAction
    }

    func body(content: Content) -> some View {
        content
            .if(leadingSwipe != .none) { view in
                view.swipeActions(edge: .leading) {
                    button(for: leadingSwipe)
                }
            }
            .if(trailingSwipe != .none) { view in
                view.swipeActions(edge: .trailing) {
                    button(for: trailingSwipe)
                }
            }
    }

    @ViewBuilder
    private func button(for swipeAction: SwipeAction) -> some View {
        VStack {
            Button(role: swipeAction.isDestructive ? .destructive : .cancel) {
                var newReadStatus: MailboxReadStatus?
                if case .toggleReadStatus = swipeAction {
                    newReadStatus = MailboxReadStatus(rawValue: !isItemRead)
                }
                guard let action = swipeAction.toAction(newReadStatus: newReadStatus) else { return }
                onTap(action, mailboxItemId)
                triggerFeedback.toggle()
            } label: {
                Image(uiImage: swipeAction.icon(isRead: isItemRead).unsafelyUnwrapped)
            }
        }
        .tint(swipeAction.color)
        .sensoryFeedback(.success, trigger: triggerFeedback)
    }
}

extension View {

    @ViewBuilder 
    func mailboxSwipeActions(
        leadingSwipe: SwipeAction,
        trailingSwipe: SwipeAction,
        isSwipeEnabled: Bool,
        mailboxItem: MailboxItemCellUIModel,
        onTapAction: @escaping MailboxSwipeActionsModifier.OnTapAction
    ) -> some View {
        if isSwipeEnabled, leadingSwipe != .none || trailingSwipe != .none {
            self.modifier(
                MailboxSwipeActionsModifier(
                    leadingSwipe: leadingSwipe,
                    trailingSwipe: trailingSwipe,
                    mailboxItemId: mailboxItem.id,
                    isItemRead: mailboxItem.isRead,
                    onTapAction: onTapAction
                )
            )
        } else {
            self
        }
    }
}
