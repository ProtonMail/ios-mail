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

import DesignSystem
import SwiftUI

struct MailboxActionBarView: View {
    typealias OnTapAction = @MainActor (Action, [PMMailboxItemId]) -> Void

    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject var selectionMode: SelectionModeState

    private let mailbox: SelectedMailbox
    private var mailboxActions: MailboxActionSettings {
        userSettings.mailboxActions
    }
    private let onTap: OnTapAction

    init(selectionMode: SelectionModeState, mailbox: SelectedMailbox, onTapAction: @escaping OnTapAction) {
        self.selectionMode = selectionMode
        self.mailbox = mailbox
        self.onTap = onTapAction
    }

    var body: some View {
        HStack(spacing: 48) {
            button(for: mailboxActions.action1)
            button(for: mailboxActions.action2)
            button(for: mailboxActions.action3)
            button(for: mailboxActions.action4)
            Button(action: {}, label: {
                Image(uiImage: DS.Icon.icThreeDotsHorizontal)
            })
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .compositingGroup()
        .shadow(radius: 2)
        .tint(DS.Color.Text.norm)
    }

    @ViewBuilder
    private func button(for mailboxAction: MailboxAction?) -> some View {
        if let action = mailboxAction?
            .toAction(
                selectionReadStatus: selectionMode.selectionStatus.readStatus,
                selectionStarStatus: selectionMode.selectionStatus.starStatus,
                systemFolder: mailbox.systemFolder ?? .inbox
            ) {
            Button(action: {
                onTap(action, selectionMode.selectedItems.map(\.id))
            }, label: {
                Image(uiImage: action.icon)
            })
        } else {
            EmptyView()
        }
    }
}

#Preview {
    let userSettings = UserSettings(
        mailboxViewMode: .conversation,
        mailboxActions: .init(
            action1: .toggleReadStatus,
            action2: .toggleStarStatus,
            action3: .moveToTrash,
            action4: .moveToArchive
        )
    )

    return VStack {
        MailboxActionBarView(
            selectionMode:.init(selectedItems: Set([.init(id: 1, isRead: false, isStarred: true)])),
            mailbox: .init(localId: 0, name: "", systemFolder: .archive),
            onTapAction: { _, _ in }
        )

        MailboxActionBarView(
            selectionMode: .init(selectedItems: Set([.init(id: 1, isRead: true, isStarred: false)])),
            mailbox: .init(localId: 0, name: "", systemFolder: .trash),
            onTapAction: { _, _ in }
        )
    }
    .environmentObject(userSettings)

}
