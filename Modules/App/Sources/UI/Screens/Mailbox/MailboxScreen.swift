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
import Combine
import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct MailboxScreen: View {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @StateObject private var mailboxModel: MailboxModel
    @State private var isComposeButtonExpanded: Bool = true
    @State private var isAccountManagerPresented = false
    @State private var animateComposeButtonSafeAreaChanges = false
    private let userSession: MailUserSession

    init(
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        userSession: MailUserSession,
        draftPresenter: DraftPresenter
    ) {
        _mailboxModel = StateObject(
            wrappedValue: MailboxModel(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                draftPresenter: draftPresenter
            )
        )
        self.userSession = userSession
    }

    // MARK: - View

    var body: some View {
        NavigationStack(path: $mailboxModel.state.navigationPath) {
            mailboxScreen
                .labelAsSheet(
                    mailbox: { mailboxModel.mailbox.unsafelyUnwrapped },
                    mailUserSession: userSession,
                    input: $mailboxModel.state.labelAsSheetPresented
                )
                .moveToSheet(
                    mailbox: { mailboxModel.mailbox.unsafelyUnwrapped },
                    mailUserSession: userSession,
                    input: $mailboxModel.state.moveToSheetPresented,
                    navigation: { _ in
                        mailboxModel.state.moveToSheetPresented = nil
                    }
                )
                .fullScreenCover(isPresented: $mailboxModel.state.isSearchPresented) {
                    SearchScreen(
                        userSession: userSession,
                        loadingBarPresenter: mailboxModel.loadingBarPresenter,
                        mailSettingsLiveQuery: mailboxModel.mailSettingsLiveQuery
                    )
                }
                .fullScreenCover(item: $mailboxModel.state.attachmentPresented) { config in
                    AttachmentView(config: config)
                        .edgesIgnoringSafeArea([.top, .bottom])
                }
                .sheet(
                    item: $mailboxModel.state.upsellPresented,
                    content: { upsellScreenModel in
                        UpsellScreen(model: upsellScreenModel)
                    }
                )
                .navigationDestination(for: MailboxItemCellUIModel.self) { uiModel in
                    mailboxItemDestination(uiModel: uiModel)
                }
                .navigationDestination(for: MailboxMessageSeed.self) { seed in
                    messageSeedDestination(seed: seed)
                }
        }
        .onChange(of: mailboxModel.toast) { showToast($1) }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
        .environment(\.confirmLink, mailboxModel.state.confirmLink)
        .environment(\.goToNextPageNotifier, mailboxModel.goToNextConversationNotifier)
        .environment(\.proceedAfterMove, mailboxModel.proceedAfterMove)
        .environmentObject(mailboxModel.loadingBarPresenter)
    }
}

extension MailboxScreen {
    private func skipAnimationWhenViewRenders() async {
        try? await Task.sleep(for: .seconds(0.1))
        animateComposeButtonSafeAreaChanges = true
    }

    private var mailboxScreen: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                MailboxListView(
                    isListAtTop: $isComposeButtonExpanded,
                    model: mailboxModel,
                    mailUserSession: userSession
                )
                composeButtonView
                    .accessibilitySortPriority(1)
                    .animation(
                        animateComposeButtonSafeAreaChanges ? .default : .none, value: geometry.safeAreaInsets.bottom
                    )
                    .onLoad {
                        Task {
                            await skipAnimationWhenViewRenders()
                        }
                    }
            }
        }
        .background(DS.Color.Background.norm)  // sets also the color for the navigation bar
        .toolbarBackground(.hidden, for: .navigationBar)  // the purpose of this is to hide the toolbar shadow
        .navigationBarTitleDisplayMode(.inline)
        .withAccountManagerSwitcher(
            isPresented: $isAccountManagerPresented,
            coordinator: mailboxModel.accountManagerCoordinator
        )
        .mainToolbar(
            title: mailboxModel.state.mailboxTitle,
            selectionMode: mailboxModel.selectionMode.selectionState,
            onEvent: handleMainToolbarEvent,
            avatarView: {
                if IOSVersion.isIOS18 {
                    mailboxModel.accountManagerCoordinator.avatarView()
                } else {
                    mailboxModel.accountManagerCoordinator.avatarView()
                        .popoverTip(NewAccountSwitcherTip())
                        .tipViewStyle(WhatsNewTipStyle())
                }
            }
        )
        .trackBottomSafeAreaForToast()
        .accessibilityElement(children: .contain)
    }

    private func handleMainToolbarEvent(_ event: MainToolbarEvent) {
        switch event {
        case .onOpenMenu:
            appUIStateStore.toggleSidebar(isOpen: true)
        case .onExitSelectionMode:
            mailboxModel.selectionMode.selectionModifier.exitSelectionMode()
        case .onSearch:
            mailboxModel.state.isSearchPresented = true
        case .onUpsell(let upsellScreenModel):
            mailboxModel.state.upsellPresented = upsellScreenModel
        }
    }

    private var composeButtonView: some View {
        ComposeButtonView(text: L10n.Mailbox.compose, isExpanded: $isComposeButtonExpanded) {
            mailboxModel.createDraft()
        }
        .padding(.trailing, DS.Spacing.large)
        .padding(.bottom, DS.Spacing.large + toastStateStore.state.maxToastHeight)
        .opacity(mailboxModel.selectionMode.selectionState.hasItems ? 0 : 1)
        .animation(.selectModeAnimation, value: mailboxModel.selectionMode.selectionState.hasItems)
        .animation(.toastAnimation, value: toastStateStore.state.maxToastHeight)
    }

    @ViewBuilder
    private func mailboxItemDestination(uiModel: MailboxItemCellUIModel) -> some View {
        conversationSeedDestination(seed: .mailboxItem(item: uiModel, selectedMailbox: mailboxModel.selectedMailbox))
    }

    @ViewBuilder
    private func messageSeedDestination(seed: MailboxMessageSeed) -> some View {
        conversationSeedDestination(seed: .pushNotification(seed))
    }

    @ViewBuilder
    private func conversationSeedDestination(seed: ConversationDetailSeed) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationsPageViewController(
                startingItem: seed,
                makeMailboxCursor: mailboxModel.mailboxCursor,
                modelToSeedMapping: ConversationDetailSeed.mailboxItem,
                draftPresenter: mailboxModel.draftPresenter,
                selectedMailbox: mailboxModel.selectedMailbox,
                userSession: userSession
            )
        }
    }

    private func showToast(_ toast: Toast?) {
        guard let toast else { return }
        DispatchQueue.main.async {
            toastStateStore.present(toast: toast)
            mailboxModel.toast = nil
        }
    }
}

private struct MailboxScreenIdentifiers {
    static let rootItem = "mailbox.rootItem"
}

class MailSettingsLiveQueryPreviewDummy: MailSettingLiveQuerying {
    // MARK: - MailSettingLiveQuerying

    var viewModeHasChanged: AnyPublisher<Void, Never> {
        Just(Void()).eraseToAnyPublisher()
    }

    func settingHasChanged<Property: Equatable>(keyPath: KeyPath<MailSettings, Property>, dropFirst: Bool) -> AnyPublisher<Property, Never> {
        Empty().eraseToAnyPublisher()
    }
}
