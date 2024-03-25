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

struct MailboxSwipeActions: ViewModifier {
    typealias Action = @MainActor (SwipeAction, PMMailboxItemId) -> Void

    @EnvironmentObject var userSettings: UserSettings
    private let itemId: PMMailboxItemId
    private let isItemRead: Bool
    private let action: Action

    var leadingSwipe: SwipeAction {
        userSettings.leadingSwipeAction
    }

    var trailingSwipe: SwipeAction {
        userSettings.trailingSwipeAction
    }

    init(itemId: PMMailboxItemId, isItemRead: Bool, action: @escaping Action) {
        self.itemId = itemId
        self.isItemRead = isItemRead
        self.action = action
    }

    func body(content: Content) -> some View {
        content
            .if(leadingSwipe.isActionAssigned) { view in
                view.swipeActions(edge: .leading) {
                    button(for: leadingSwipe)
                }
            }
            .if(trailingSwipe.isActionAssigned) { view in
                view.swipeActions(edge: .trailing) {
                    button(for: trailingSwipe)
                }
            }
    }

    @ViewBuilder
    private func button(for swipeAction: SwipeAction) -> some View {
        VStack {
            Button(role: swipeAction.isDestructive ? .destructive : .cancel) {
                action(swipeAction, itemId)
            } label: {
                Image(uiImage: swipeAction.icon(isStatusRead: isItemRead))
            }
        }
        .tint(swipeAction.color)
    }
}

extension View {
    @MainActor func mailboxSwipeActions(itemId: PMMailboxItemId, isItemRead: Bool, action: @escaping MailboxSwipeActions.Action) -> some View {
        self.modifier(MailboxSwipeActions(itemId: itemId, isItemRead: isItemRead, action: action))
    }
}
