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

import Combine
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

@main
struct ProtonMailApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // declaration of state objects
    private let appUIStateStore = AppUIStateStore()
    private let legacyMigrationStateStore: LegacyMigrationStateStore
    private let toastStateStore = ToastStateStore(initialState: .initial)
    @StateObject var appAppearanceStore = AppAppearanceStore.shared

    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                RootView(appContext: .shared)
                    .environment(\.mainWindowSize, proxy.size)
                    .environmentObject(appUIStateStore)
                    .environmentObject(legacyMigrationStateStore)
                    .environmentObject(toastStateStore)
                    .environmentObject(appAppearanceStore)
            }
            .task {
                await appAppearanceStore.updateColorScheme()
            }
            .preferredColorScheme(appAppearanceStore.colorScheme)
        }
    }

    init() {
        legacyMigrationStateStore = .init(toastStateStore: toastStateStore)
    }
}

private struct RootView: View {
    @EnvironmentObject private var sceneDelegate: SceneDelegate
    @EnvironmentObject private var legacyMigrationStateStore: LegacyMigrationStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore

    // The route determines the screen that will be rendered
    @ObservedObject private var appContext: AppContext
    @StateObject private var emailsPrefetchingTrigger: EmailsPrefetchingTrigger

    private let recurringBackgroundTaskScheduler: RecurringBackgroundTaskScheduler

    init(
        appContext: AppContext,
        emailsPrefetchingNotifier: EmailsPrefetchingNotifier = EmailsPrefetchingNotifier.shared
    ) {
        self.appContext = appContext
        self._emailsPrefetchingTrigger = .init(wrappedValue: .init(
            emailsPrefetchingNotifier: emailsPrefetchingNotifier,
            sessionProvider: appContext,
            prefetch: prefetch
        ))
        self.recurringBackgroundTaskScheduler = .init(
            backgroundTaskExecutorProvider: { appContext.mailSession }
        )
    }

    var body: some View {
        mainView()
            .onAppear {
                sceneDelegate.toastStateStore = toastStateStore
            }
            .onChange(of: appContext.sessionState) { old, new in
                if new.isAuthorized {
                    EmailsPrefetchingNotifier.shared.notify()
                    submitBackgroundTask()
                }
                if new == .noSession {
                    recurringBackgroundTaskScheduler.cancel()
                }
            }
            .onLoad {
                emailsPrefetchingTrigger.setUpSubscription()
            }
    }

    // MARK: - Private

    @ViewBuilder
    private func mainView() -> some View {
        ZStack {
            Group {
                switch appContext.sessionState {
                case .noSession:
                    noSessionView(migrationState: legacyMigrationStateStore.state)

                case .activeSession(let activeUserSession):
                    HomeScreen(
                        appContext: appContext,
                        userSession: activeUserSession,
                        toastStateStore: toastStateStore
                    )
                    .id(activeUserSession.userId()) // Forces the child view to be recreated when the user account changes

                case .activeSessionTransition:
                    SessionTransitionScreen()
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut, value: appContext.sessionState)
    }

    @ViewBuilder
    private func noSessionView(migrationState: LegacyMigrationStateStore.State) -> some View {
        switch migrationState {
        case .checkingIfMigrationIsNeeded:
            EmptyView()
        case .inProgress:
            SessionTransitionScreen()
        case .biometricUnlockRequired:
            BiometricLockScreen(
                authenticationMethod: .external {
                    try await legacyMigrationStateStore.resumeByRequestABiometryCheck()
                }, output: { _ in }
            )
        case .pinRequired(let errorFromLatestAttempt):
            PINLockScreen(
                state: .init(hideLogoutButton: false, pin: .empty),
                error: .constant(errorFromLatestAttempt)
            ) { output in
                switch output {
                case .pin(let pin):
                    legacyMigrationStateStore.resumeMigration(using: pin)
                case .logOut:
                    legacyMigrationStateStore.abortMigration()
                }
            }
        case .willNotMigrate:
            appContext.accountAuthCoordinator.accountView()
        }
    }

    private func submitBackgroundTask() {
        Task {
            await recurringBackgroundTaskScheduler.submit()
        }
    }
}

private struct SessionTransitionScreen: View {
    @State private var showLoadingScreen = false

    private let userDefaultsWithPromptsDisabled: UserDefaults = {
        let userDefaults = UserDefaults(suiteName: "transition")!
        userDefaults.set(false, forKey: UserDefaultsKey.showAlphaV1Onboarding.rawValue)
        userDefaults[.notificationAuthorizationRequestDates] = [Date.now]
        return userDefaults
    }()

    var body: some View {
        if showLoadingScreen {
            ZStack {
                fakeMailboxScreen

                progressView
            }
        } else {
            Color.clear
                .onLoad {
                    Task {
                        try await Task.sleep(for: .seconds(1))
                        showLoadingScreen = true
                    }
                }
        }
    }

    private var fakeMailboxScreen: some View {
        MailboxScreen(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: .initialState,
            notificationAuthorizationStore: .init(userDefaults: userDefaultsWithPromptsDisabled),
            userSession: .init(noPointer: .init()),
            userDefaults: userDefaultsWithPromptsDisabled,
            draftPresenter: .dummy,
            sendResultPresenter: .init(undoSendProvider: .mockInstance, draftPresenter: .dummy)
        )
        .blur(radius: 5)
        .allowsHitTesting(false)
    }

    private var progressView: some View {
        VStack(spacing: 0) {
            ProtonSpinner()

            Spacer()
                .frame(height: DS.Spacing.huge)

            Text(L10n.Session.Transition.title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.Text.norm)

            Spacer()
                .frame(height: DS.Spacing.mediumLight)

            Text(L10n.Session.Transition.body)
                .font(.callout)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
        }
        .offset(y: -50)
        .padding(.horizontal, DS.Spacing.jumbo)
    }
}
