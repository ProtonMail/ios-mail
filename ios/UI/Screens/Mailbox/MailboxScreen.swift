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
    @EnvironmentObject var toastStateStore: ToastStateStore
    @StateObject private var mailboxModel: MailboxModel
    @State private var isComposeButtonExpanded: Bool = true
    private var customLabelModel: CustomLabelModel

    private var navigationTitle: LocalizedStringResource {
        let selectionMode = mailboxModel.selectionMode
        let hasSelectedItems = selectionMode.hasSelectedItems
        let selectedItemsCount = selectionMode.selectedItems.count
        let selectedMailboxName = mailboxModel.selectedMailbox.name

        return hasSelectedItems ? L10n.Mailbox.selected(emailsCount: selectedItemsCount) : selectedMailboxName
    }

    init(
        customLabelModel: CustomLabelModel,
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        openedItem: MailboxMessageSeed? = nil
    ) {
        self._mailboxModel = StateObject(
            wrappedValue: MailboxModel(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                openedItem: openedItem
            )
        )
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
                    mailboxItemDestination(uiModel: uiModel)
                }
                .navigationDestination(for: MailboxMessageSeed.self) { seed in
                    messageSeedDestination(seed: seed)
                }
        }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
    }
}

extension MailboxScreen {

    private var mailboxScreen: some View {
        ZStack(alignment: .bottomTrailing) {
            MailboxListView(isListAtTop: $isComposeButtonExpanded, model: mailboxModel)
            composeButtonView
                .accessibilitySortPriority(1)
            mailboxActionBarView
        }
        .background(DS.Color.Background.norm) // sets also the color for the navigation bar
        .navigationBarTitleDisplayMode(.inline)
        .mainToolbar(title: navigationTitle, selectionMode: mailboxModel.selectionMode)
        .accessibilityElement(children: .contain)
    }

    private var composeButtonView: some View {
        ComposeButtonView(text: L10n.Mailbox.compose, isExpanded: $isComposeButtonExpanded) {
            toastStateStore.present(toast: .comingSoon)
        }
        .padding(.trailing, DS.Spacing.large)
        .padding(.bottom, DS.Spacing.large + toastStateStore.state.maxHeight)
        .opacity(mailboxModel.selectionMode.hasSelectedItems ? 0 : 1)
        .animation(.selectModeAnimation, value: mailboxModel.selectionMode.hasSelectedItems)
        .animation(.toastAnimation, value: toastStateStore.state.toastHeights)
    }

    private var mailboxActionBarView: some View {
        MailboxActionBarView(
            selectionMode: mailboxModel.selectionMode,
            selectedMailbox: mailboxModel.selectedMailbox,
            mailboxActionable: mailboxModel,
            customLabelModel: customLabelModel
        )
        .opacity(mailboxModel.selectionMode.hasSelectedItems ? 1 : 0)
        .offset(y: mailboxModel.selectionMode.hasSelectedItems ? 0 : 45 + 100)
        .animation(.selectModeAnimation, value: mailboxModel.selectionMode.hasSelectedItems)
    }

    @ViewBuilder
    private func mailboxItemDestination(uiModel: MailboxItemCellUIModel) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationDetailScreen(seed: .mailboxItem(item: uiModel, selectedMailbox: mailboxModel.selectedMailbox))
        }
    }

    @ViewBuilder
    private func messageSeedDestination(seed: MailboxMessageSeed) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationDetailScreen(
                seed: .message(localID: seed.localID, subject: seed.subject, sender: seed.sender)
            )
        }
    }
}

private extension Animation {
    static let selectModeAnimation = Animation.easeInOut(duration: AppConstants.selectionModeStartDuration)
}

#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userSettings = UserSettings(mailboxActions: .init())
    let customLabelModel = CustomLabelModel()

    return MailboxScreen(
        customLabelModel: customLabelModel,
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState
    )
        .environmentObject(appUIStateStore)
        .environmentObject(toastStateStore)
        .environmentObject(userSettings)
}

private struct MailboxScreenIdentifiers {
    static let rootItem = "mailbox.rootItem"
}

import Combine
import proton_app_uniffi

class MailSettingsLiveQueryPreviewDummy: MailSettingLiveQuerying {

    // MARK: - MailSettingLiveQuerying

    var settingsPublisher: AnyPublisher<MailSettings, Never> {
        Just(.defaults()).eraseToAnyPublisher()
    }

}
