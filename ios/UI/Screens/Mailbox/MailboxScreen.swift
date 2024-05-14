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
    private var customLabelModel: CustomLabelModel

    private var navigationTitle: String {
        selectionMode.hasSelectedItems
        ? LocalizationTemp.Selection.title(value: selectionMode.selectedItems.count)
        : appRoute.selectedMailbox.name
    }

    init(mailboxModel: MailboxModel, customLabelModel: CustomLabelModel) {
        self.mailboxModel = mailboxModel
        self.appRoute = mailboxModel.appRoute
        self.selectionMode = mailboxModel.selectionMode
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mailboxScreen
                mailboxActionBarView
            }
            .background(DS.Color.Background.norm) // sets also the color for the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            .mailboxToolbar(title: navigationTitle, selectionMode: selectionMode)
            .sensoryFeedback(trigger: selectionMode.selectedItems) { oldValue, newValue in
                oldValue.count != newValue.count ? .selection : nil
            }
            .accessibilityElement(children: .contain)
        }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
    }
}

extension MailboxScreen {

    @ViewBuilder
    private var mailboxScreen: some View {
        if userSettings.mailboxViewMode == .conversation {
            MailboxConversationScreen(model: mailboxModel.conversationModel)
        } else {
            Text("message list mailbox")
        }
    }

    private var mailboxActionable: MailboxActionable {
        if userSettings.mailboxViewMode == .conversation {
            return mailboxModel.conversationModel
        } else {
            // TODO: ...
            return EmptyMailboxActionable()
        }
    }

    private var mailboxActionBarView: some View {
        MailboxActionBarView(
            selectionMode: selectionMode,
            mailbox: appRoute.selectedMailbox,
            mailboxActionable: mailboxActionable,
            customLabelModel: customLabelModel
        )
        .opacity(selectionMode.hasSelectedItems ? 1 : 0)
        .offset(y: selectionMode.hasSelectedItems ? 0 : 45 + 100)
        .animation(
            .easeInOut(duration: AppConstants.selectionModeStartDuration),
            value: selectionMode.hasSelectedItems
        )
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: false)
    let userSettings = UserSettings(mailboxViewMode: .conversation, mailboxActions: .init())

    let mailboxModel = MailboxModel(appRoute: .shared, state: .data( PreviewData.mailboxConversations))
    let customLabelModel = CustomLabelModel()

    return MailboxScreen(mailboxModel: mailboxModel, customLabelModel: customLabelModel)
        .environmentObject(appUIState)
        .environmentObject(userSettings)
}

private struct MailboxScreenIdentifiers {
    static let rootItem = "mailbox.rootItem"
}
