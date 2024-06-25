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
    typealias OnTapAction = @MainActor (Action, [PMMailboxItemId]) -> Void

    @EnvironmentObject private var userSettings: UserSettings
    @State private(set) var triggerFeedback = false
    private let isSelectionModeOn: Bool
    private let itemId: PMMailboxItemId
    private let systemFolder: SystemFolderIdentifier?
    private let isItemRead: Bool
    private let onTap: OnTapAction

    var leadingSwipe: SwipeAction {
        userSettings.leadingSwipeAction
    }

    var trailingSwipe: SwipeAction {
        userSettings.trailingSwipeAction
    }

    init(isSelectionModeOn: Bool, itemId: PMMailboxItemId, systemFolder: SystemFolderIdentifier?, isItemRead: Bool, onTapAction: @escaping OnTapAction) {
        self.isSelectionModeOn = isSelectionModeOn
        self.itemId = itemId
        self.systemFolder = systemFolder
        self.isItemRead = isItemRead
        self.onTap = onTapAction
    }

    func body(content: Content) -> some View {
        if isSelectionModeOn {
            content
        } else {
            content
                .if(leadingSwipe.isActionAssigned(systemFolder: systemFolder)) { view in
                    view.swipeActions(edge: .leading) {
                        button(for: leadingSwipe)
                    }
                }
                .if(trailingSwipe.isActionAssigned(systemFolder: systemFolder)) { view in
                    view.swipeActions(edge: .trailing) {
                        button(for: trailingSwipe)
                    }
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
                onTap(action, [itemId])
                triggerFeedback.toggle()
            } label: {
                Image(uiImage: swipeAction.icon(readStatus: isItemRead ? .allRead : .noneRead))
            }
        }
        .tint(swipeAction.color)
        .sensoryFeedback(.success, trigger: triggerFeedback)
    }
}

extension View {

    @MainActor func mailboxSwipeActions(
        isSelectionModeOn: Bool,
        itemId: PMMailboxItemId,
        systemFolder: SystemFolderIdentifier?,
        isItemRead: Bool,
        onTapAction: @escaping MailboxSwipeActionsModifier.OnTapAction
    ) -> some View {
        self.modifier(
            MailboxSwipeActionsModifier(
                isSelectionModeOn: isSelectionModeOn,
                itemId: itemId,
                systemFolder: systemFolder,
                isItemRead: isItemRead,
                onTapAction: onTapAction
            )
        )
    }
}
