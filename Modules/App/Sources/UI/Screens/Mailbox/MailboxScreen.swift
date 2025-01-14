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

import AccountManager
import InboxComposer
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct MailboxScreen: View {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject var toastStateStore: ToastStateStore
    @StateObject private var mailboxModel: MailboxModel
    @State private var isComposeButtonExpanded: Bool = true
    @State private var isSearchPresented = false
    @State private var isOnboardingPresented = false
    private let onboardingStore: OnboardingStore

    init(
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        userDefaults: UserDefaults,
        openedItem: MailboxMessageSeed? = nil
    ) {
        self._mailboxModel = StateObject(
            wrappedValue: MailboxModel(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                openedItem: openedItem
            )
        )
        self.onboardingStore = .init(userDefaults: userDefaults)
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        NavigationStack(path: $mailboxModel.state.navigationPath) {
            mailboxScreen
                .sheetTestable(
                    isPresented: $isOnboardingPresented,
                    onDismiss: { onboardingStore.shouldShowOnboarding = false },
                    content: { OnboardingScreen() }
                )
                .fullScreenCover(isPresented: $isSearchPresented) {
                    SearchScreen()
                }
                .fullScreenCover(item: $mailboxModel.state.attachmentPresented) { config in
                    AttachmentView(config: config)
                        .edgesIgnoringSafeArea([.top, .bottom])
                }
                .navigationDestination(for: MailboxItemCellUIModel.self) { uiModel in
                    mailboxItemDestination(uiModel: uiModel)
                }
                .navigationDestination(for: MailboxMessageSeed.self) { seed in
                    messageSeedDestination(seed: seed)
                }
                .sheet(item: $mailboxModel.presentedDraft) { presentedDraft in
                    composerView(presentedDraft: presentedDraft)
                }
        }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
        .onAppear {
            let workItem = DispatchWorkItem {
                isOnboardingPresented = onboardingStore.shouldShowOnboarding
            }
            Dispatcher.dispatchOnMainAfter(.now() + .milliseconds(500), workItem)
            didAppear?(self)
        }
    }
}

extension MailboxScreen {

    private var mailboxScreen: some View {
        ZStack(alignment: .bottomTrailing) {
            MailboxListView(
                isListAtTop: $isComposeButtonExpanded,
                model: mailboxModel
            )
            composeButtonView
                .accessibilitySortPriority(1)
        }
        .background(DS.Color.Background.norm) // sets also the color for the navigation bar
        .toolbarBackground(.hidden, for: .navigationBar) // the purpose of this is to hide the toolbar shadow
        .navigationBarTitleDisplayMode(.inline)
        .withAccountManager(coordinator: $mailboxModel.accountManagerCoordinator)
        .mainToolbar(
            title: mailboxModel.state.mailboxTitle,
            selectionMode: mailboxModel.selectionMode.selectionState,
            onEvent: handleMainToolbarEvent
        )
        .accessibilityElement(children: .contain)
    }

    private func handleMainToolbarEvent(_ event: MainToolbarEvent) {
        switch event {
        case .onOpenMenu:
            appUIStateStore.sidebarState.isOpen = true
        case .onExitSelectionMode:
            mailboxModel.selectionMode.selectionModifier.exitSelectionMode()
        case .onSearch:
            isSearchPresented = true
        }
    }

    private var composeButtonView: some View {
        ComposeButtonView(text: L10n.Mailbox.compose, isExpanded: $isComposeButtonExpanded) {
            mailboxModel.createDraft()
        }
        .padding(.trailing, DS.Spacing.large)
        .padding(.bottom, DS.Spacing.large + toastStateStore.state.maxHeight)
        .opacity(mailboxModel.selectionMode.selectionState.hasItems ? 0 : 1)
        .animation(.selectModeAnimation, value: mailboxModel.selectionMode.selectionState.hasItems)
        .animation(.toastAnimation, value: toastStateStore.state.toastHeights)
    }

    @ViewBuilder
    private func mailboxItemDestination(uiModel: MailboxItemCellUIModel) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationDetailScreen(
                seed: .mailboxItem(item: uiModel, selectedMailbox: mailboxModel.selectedMailbox),
                navigationPath: $mailboxModel.state.navigationPath
            )
        }
    }

    @ViewBuilder
    private func messageSeedDestination(seed: MailboxMessageSeed) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationDetailScreen(seed: .message(seed), navigationPath: $mailboxModel.state.navigationPath)
        }
    }

    @ViewBuilder
    private func composerView(presentedDraft: PresentedDraft) -> some View {
        let contactProvider = ComposerContactProvider.productionInstance(session: mailboxModel.userSession)
        switch presentedDraft {
        case .new(let draft):
            ComposerScreen(draft: draft, draftOrigin: .new, contactProvider: contactProvider)
        case .openDraftId(let messageId):
            ComposerScreen(
                messageId: messageId,
                contactProvider: contactProvider,
                userSession: mailboxModel.userSession
            )
        }
    }
}

#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userSettings = UserSettings()
    let userDefaults = UserDefaults(suiteName: "mailbox_preview")!

    return MailboxScreen(
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState,
        userDefaults: userDefaults
    )
        .environmentObject(appUIStateStore)
        .environmentObject(toastStateStore)
        .environmentObject(userSettings)
}

private struct MailboxScreenIdentifiers {
    static let rootItem = "mailbox.rootItem"
}

import Combine

class MailSettingsLiveQueryPreviewDummy: MailSettingLiveQuerying {

    // MARK: - MailSettingLiveQuerying

    var viewModeHasChanged: AnyPublisher<Void, Never> {
        Just(Void()).eraseToAnyPublisher()
    }
}
