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

struct MailboxScreen: View {
    @EnvironmentObject private var userSettings: UserSettings

    @ObservedObject private var appRoute: AppRouteState
    @ObservedObject private var selectionMode: SelectionModeState

    private var mailboxModel: MailboxModel

    private var navigationTitle: String {
        selectionMode.hasSelectedItems
        ? LocalizationTemp.Selection.title(value: selectionMode.selectedItems.count)
        : appRoute.selectedMailbox.name
    }

    init(mailboxModel: MailboxModel) {
        self.mailboxModel = mailboxModel
        self.appRoute = mailboxModel.appRoute
        self.selectionMode = mailboxModel.selectionMode
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if userSettings.mailboxViewMode == .conversation {
                    MailboxConversationScreen(model: mailboxModel.conversationModel)
                } else {
                    Text("message list mailbox")
                }

                MailboxActionBarView(
                    selectionMode: selectionMode,
                    mailbox: appRoute.selectedMailbox
                ) { action, itemIds in
                    if userSettings.mailboxViewMode == .conversation {
                        mailboxModel.conversationModel.onConversationAction(action, conversationIds: itemIds)
                    } else {
                        AppLogger.logTemporarily(message: "\(action) for message not implemented", isError: true)
                    }
                }
                .opacity(selectionMode.hasSelectedItems ? 1 : 0)
                .offset(y: selectionMode.hasSelectedItems ? 0 : 45 + 100)
                .animation(
                    .easeInOut(duration: AppConstants.selectionModeStartDuration),
                    value: selectionMode.hasSelectedItems
                )
            }
            .background(DS.Color.Background.norm) // sets also the color for the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            .mailboxToolbar(title: navigationTitle, selectionMode: selectionMode)
            .sensoryFeedback(trigger: selectionMode.selectedItems) { oldValue, newValue in
                oldValue.count != newValue.count ? .selection : nil
            }
        }
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: false)
    let userSettings = UserSettings(mailboxViewMode: .conversation, mailboxActions: .init())

    let mailboxModel = MailboxModel(appRoute: .shared, state: .data( PreviewData.mailboxConversations))

    return MailboxScreen(mailboxModel: mailboxModel)
        .environmentObject(appUIState)
        .environmentObject(userSettings)
}
