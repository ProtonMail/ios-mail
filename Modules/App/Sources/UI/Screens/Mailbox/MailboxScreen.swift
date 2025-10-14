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
import InboxIAP
import proton_app_uniffi
import SwiftUI

struct MailboxScreen: View {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @EnvironmentObject private var upsellCoordinator: UpsellCoordinator
    @Environment(\.isUpsellButtonVisible) private var isUpsellButtonVisible
    @StateObject private var mailboxModel: MailboxModel
    @State private var isComposeButtonExpanded: Bool = true
    @State private var isOnboardingPresented = false
    @State private var isNotificationPromptPresented = false
    @State private var isAccountManagerPresented = false
    @State private var animateComposeButtonSafeAreaChanges = false
    private let userSession: MailUserSession
    private let notificationAuthorizationStore: NotificationAuthorizationStore
    private let userDefaults: UserDefaults

    private var shouldShowOnboardingUpsell: Bool {
        isUpsellButtonVisible && !userDefaults[.hasSeenOnboardingUpsell]
    }

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
                    SearchScreen(userSession: userSession)
                }
                .fullScreenCover(item: $mailboxModel.state.attachmentPresented) { config in
                    AttachmentView(config: config)
                        .edgesIgnoringSafeArea([.top, .bottom])
                }
                .sheet(item: $mailboxModel.state.upsellPresented) { upsellScreenModel in
                    UpsellScreen(model: upsellScreenModel)
                }
                .sheet(
                    item: $mailboxModel.state.onboardingUpsellPresented,
                    onDismiss: onboardingUpsellDismissed,
                    content: { upsellScreenModel in
                        OnboardingUpsellScreen(model: upsellScreenModel)
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
        .onAppear {
            let workItem = DispatchWorkItem {
                Task {
                    await presentAppropriateIntroductoryView()
                }
            }
            Dispatcher.dispatchOnMainAfter(.now() + .milliseconds(500), workItem)
            didAppear?(self)
        }
        .environment(\.confirmLink, mailboxModel.state.confirmLink)
    }

    private func onboardingScreenDismissed() {
        userDefaults[.hasSeenAlphaOnboarding] = true

        Task {
            await presentAppropriateIntroductoryView()
        }
    }

    private func onboardingUpsellDismissed() {
        userDefaults[.hasSeenOnboardingUpsell] = true

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

        if introductionProgress == .upsell {
            do {
                mailboxModel.state.onboardingUpsellPresented = try await upsellCoordinator.presentOnboardingUpsellScreen()
            } catch {
                AppLogger.log(error: error, category: .payments)
                onboardingUpsellDismissed()
            }
        }
    }

    private func calculateIntroductionProgress() async -> IntroductionProgress {
        if !userDefaults[.hasSeenAlphaOnboarding] {
            return .onboarding
        } else if await notificationAuthorizationStore.shouldRequestAuthorization(trigger: .onboardingFinished) {
            return .notifications
        } else if shouldShowOnboardingUpsell {
            return .upsell
        } else {
            return .finished
        }
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
        case .onUpsell(let upsellScreenModel):
            mailboxModel.state.upsellPresented = upsellScreenModel
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
        let mailboxCursor = mailboxModel.mailboxCursor(uiModel: uiModel)!

        SidebarZIndexUpdateContainer {
            ConversationsPageViewController(
                startingItem: uiModel,
                mailboxCursor: mailboxCursor,
                draftPresenter: mailboxModel.draftPresenter,
                navigationPath: $mailboxModel.state.navigationPath,
                selectedMailbox: mailboxModel.selectedMailbox,
                userSession: userSession,
                customSettings: customSettings(ctx: userSession)
            )
        }
    }

    @ViewBuilder
    private func messageSeedDestination(seed: MailboxMessageSeed) -> some View {
        SidebarZIndexUpdateContainer {
            PagelessConversationDetailScreen(
                seed: .pushNotification(seed),
                draftPresenter: mailboxModel.draftPresenter,
                navigationPath: $mailboxModel.state.navigationPath,
                mailUserSession: userSession
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
        case upsell
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
        userSession: .dummy,
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

    func settingHasChanged<Property: Equatable>(keyPath: KeyPath<MailSettings, Property>, dropFirst: Bool) -> AnyPublisher<Property, Never> {
        Empty().eraseToAnyPublisher()
    }
}
