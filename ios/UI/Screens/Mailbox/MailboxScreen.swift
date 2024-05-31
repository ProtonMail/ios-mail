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
    @StateObject private var mailboxModel: MailboxModel

    private var customLabelModel: CustomLabelModel

    private var navigationTitle: String {
        mailboxModel.selectionMode.hasSelectedItems
        ? LocalizationTemp.Selection.title(value: mailboxModel.selectionMode.selectedItems.count)
        : mailboxModel.selectedMailbox.name
    }

    init(customLabelModel: CustomLabelModel, mailSettings: PMMailSettingsProtocol, openedItem: MailboxItemSeed? = nil) {
        self._mailboxModel = StateObject(wrappedValue: MailboxModel(mailSettings: mailSettings, openedItem: openedItem))
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        NavigationStack(path: $mailboxModel.navigationPath) {
            mailboxScreen
                .fullScreenCover(item: $mailboxModel.attachmentPresented) { config in
                    AttachmentView(config: config)
                        .edgesIgnoringSafeArea([.top, .bottom])
                }
                .navigationDestination(for: MailboxItemCellUIModel.self) { uiModel in
                    ConversationScreen(seed: .mailboxItem(uiModel))
                }
                .navigationDestination(for: MailboxItemSeed.self) { info in
                    ConversationScreen(seed: .pushNotification(messageId: info.messageId, subject: info.subject, sender: info.sender))
                }
        }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
    }
}

extension MailboxScreen {

    private var mailboxScreen: some View {
        ZStack(alignment: .bottom) {
            MailboxListView(model: mailboxModel)
            mailboxActionBarView
        }
        .background(DS.Color.Background.norm) // sets also the color for the navigation bar
        .navigationBarTitleDisplayMode(.inline)
        .mainToolbar(title: navigationTitle, selectionMode: mailboxModel.selectionMode)
        .accessibilityElement(children: .contain)
    }

    private var mailboxActionBarView: some View {
        MailboxActionBarView(
            selectionMode: mailboxModel.selectionMode,
            mailbox: mailboxModel.selectedMailbox,
            mailboxActionable: mailboxModel,
            customLabelModel: customLabelModel
        )
        .opacity(mailboxModel.selectionMode.hasSelectedItems ? 1 : 0)
        .offset(y: mailboxModel.selectionMode.hasSelectedItems ? 0 : 45 + 100)
        .animation(
            .easeInOut(duration: AppConstants.selectionModeStartDuration),
            value: mailboxModel.selectionMode.hasSelectedItems
        )
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: false)
    let customLabelModel = CustomLabelModel()
    let dummySettings = EmptyPMMailSettings()

    return MailboxScreen(customLabelModel: customLabelModel, mailSettings: dummySettings)
        .environmentObject(appUIState)
}

private struct MailboxScreenIdentifiers {
    static let rootItem = "mailbox.rootItem"
}
