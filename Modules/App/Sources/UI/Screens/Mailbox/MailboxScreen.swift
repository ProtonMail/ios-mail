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
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct MailboxScreen: View {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @StateObject private var mailboxModel: MailboxModel
    @State private var isComposeButtonExpanded: Bool = true
    @State private var isOnboardingPresented = false
    @State private var isNotificationPromptPresented = false
    @State private var isAccountManagerPresented = false
    private let userSession: MailUserSession
    private let notificationAuthorizationStore: NotificationAuthorizationStore
    private let userDefaults: UserDefaults

    init(
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        notificationAuthorizationStore: NotificationAuthorizationStore,
        userSession: MailUserSession,
        userDefaults: UserDefaults,
        draftPresenter: DraftPresenter
    ) {
        self._mailboxModel = StateObject(
            wrappedValue: MailboxModel(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                draftPresenter: draftPresenter
            )
        )
        self.notificationAuthorizationStore = notificationAuthorizationStore
        self.userSession = userSession
        self.userDefaults = userDefaults
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        NavigationStack(path: $mailboxModel.state.navigationPath) {
            mailboxScreen
                .sheetTestable(
                    isPresented: $isOnboardingPresented,
                    onDismiss: { onboardingScreenDismissed() },
                    content: { OnboardingScreen() }
                )
                .sheetTestable(
                    isPresented: $isNotificationPromptPresented,
                    content: {
                        NotificationAuthorizationPrompt(
                            trigger: .onboardingFinished,
                            userDidRespond: userDidRespondToAuthorizationRequest
                        )
                    }
                )
                .labelAsSheet(
                    mailbox: { mailboxModel.mailbox.unsafelyUnwrapped },
                    input: $mailboxModel.state.labelAsSheetPresented
                )
                .moveToSheet(
                    mailbox: { mailboxModel.mailbox.unsafelyUnwrapped },
                    input: $mailboxModel.state.moveToSheetPresented
                )
                .fullScreenCover(isPresented: $mailboxModel.state.isSearchPresented) {
                    SearchScreen(userSession: userSession)
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
        }
        .onChange(of: mailboxModel.toast) { showToast($1) }
        .accessibilityIdentifier(MailboxScreenIdentifiers.rootItem)
        .accessibilityElement(children: .contain)
        .onAppear {
            let workItem = DispatchWorkItem {
                Task {
                    await presentAppropriateIntroductoryView()
                }
            }
            Dispatcher.dispatchOnMainAfter(.now() + .milliseconds(500), workItem)
            didAppear?(self)
        }
    }

    private func onboardingScreenDismissed() {
        userDefaults[.showAlphaV1Onboarding] = false

        Task {
            await presentAppropriateIntroductoryView()
        }
    }

    private func userDidRespondToAuthorizationRequest(accepted: Bool) {
        Task {
            await notificationAuthorizationStore.userDidRespondToAuthorizationRequest(accepted: accepted)
            await presentAppropriateIntroductoryView()
        }
    }

    private func presentAppropriateIntroductoryView() async {
        let introductionProgress = await calculateIntroductionProgress()
        isOnboardingPresented = introductionProgress == .onboarding
        isNotificationPromptPresented = introductionProgress == .notifications
    }

    private func calculateIntroductionProgress() async -> IntroductionProgress {
        if userDefaults[.showAlphaV1Onboarding] {
            return .onboarding
        } else if await notificationAuthorizationStore.shouldRequestAuthorization(trigger: .onboardingFinished) {
            return .notifications
        } else {
            return .finished
        }
    }
}

extension MailboxScreen {

    private var mailboxScreen: some View {
        ZStack(alignment: .bottomTrailing) {
            MailboxListView(
                isListAtTop: $isComposeButtonExpanded,
                model: mailboxModel,
                mailUserSession: userSession
            )
            composeButtonView
                .accessibilitySortPriority(1)
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
            avatarView: { mailboxModel.accountManagerCoordinator.avatarView() }
        )
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
        }
    }

    private var composeButtonView: some View {
        ComposeButtonView(text: L10n.Mailbox.compose, isExpanded: $isComposeButtonExpanded) {
            mailboxModel.createDraft(toastStateStore: toastStateStore)
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
                draftPresenter: mailboxModel.draftPresenter,
                navigationPath: $mailboxModel.state.navigationPath
            )
        }
    }

    @ViewBuilder
    private func messageSeedDestination(seed: MailboxMessageSeed) -> some View {
        SidebarZIndexUpdateContainer {
            ConversationDetailScreen(
                seed: .pushNotification(seed),
                draftPresenter: mailboxModel.draftPresenter,
                navigationPath: $mailboxModel.state.navigationPath
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

extension MailboxScreen {
    enum IntroductionProgress {
        case onboarding
        case notifications
        case finished
    }
}

#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userDefaults = UserDefaults(suiteName: "mailbox_preview")!

    MailboxScreen(
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState,
        notificationAuthorizationStore: .init(userDefaults: userDefaults),
        userSession: .init(noPointer: .init()),
        userDefaults: userDefaults,
        draftPresenter: .dummy()
    )
    .environmentObject(appUIStateStore)
    .environmentObject(toastStateStore)
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

    func settingHasChanged<Property: Equatable>(keyPath: KeyPath<MailSettings, Property>) -> AnyPublisher<Property, Never> {
        Empty().eraseToAnyPublisher()
    }
}
