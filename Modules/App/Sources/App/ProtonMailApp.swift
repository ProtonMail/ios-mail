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
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ProtonMailApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // declaration of state objects
    private let analytics = Analytics()
    private let appUIStateStore = AppUIStateStore()
    private let legacyMigrationStateStore: LegacyMigrationStateStore
    private let refreshToolbarNotifier = RefreshToolbarNotifier()
    private let toastStateStore = ToastStateStore(initialState: .initial)
    @StateObject var appAppearanceStore = AppAppearanceStore.shared

    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                RootView(appContext: .shared)
                    .environment(\.mainWindowSize, proxy.size)
                    .environmentObject(appUIStateStore)
                    .environmentObject(legacyMigrationStateStore)
                    .environmentObject(refreshToolbarNotifier)
                    .environmentObject(toastStateStore)
                    .environmentObject(appAppearanceStore)
                    .environmentObject(analytics)
            }
            .task {
                async let analytics: Void = configureAnalyticsIfNeeded(analytics: analytics)
                async let updateColorScheme: Void = appAppearanceStore.updateColorScheme()
                _ = await (analytics, updateColorScheme)
            }
            .preferredColorScheme(appAppearanceStore.colorScheme)
        }
    }

    init() {
        legacyMigrationStateStore = .init(toastStateStore: toastStateStore)
        DynamicFontSize.capSupportedSizeCategories()
    }

    func configureAnalyticsIfNeeded(analytics: Analytics) async {
        if AnalyticsState.shouldConfigureAnalytics {
            await analytics.enable(configuration: .default)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var sceneDelegate: SceneDelegate
    @EnvironmentObject private var legacyMigrationStateStore: LegacyMigrationStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @EnvironmentObject private var analytics: Analytics

    // The route determines the screen that will be rendered
    @ObservedObject private var appContext: AppContext

    @State private var isDuplicateAlertPresented = false

    private let recurringBackgroundTaskScheduler: RecurringBackgroundTaskScheduler

    init(
        appContext: AppContext
    ) {
        self.appContext = appContext
        self.recurringBackgroundTaskScheduler = .init(
            backgroundTaskExecutorProvider: { appContext.mailSession }
        )
    }

    var body: some View {
        mainView()
            .onAppear {
                sceneDelegate.toastStateStore = toastStateStore
                observeAndDisplayAppContextErrors()
            }
            .onChange(of: appContext.sessionState) { old, new in
                if new.isAuthorized {
                    submitBackgroundTask()
                }
                if new == .noSession {
                    recurringBackgroundTaskScheduler.cancel()
                }
            }
            .withDuplicateAccountAlert(
                isPresented: $isDuplicateAlertPresented,
                coordinator: appContext.accountAuthCoordinator
            )
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
                        toastStateStore: toastStateStore,
                        analytics: analytics
                    )
                    .id(activeUserSession.userId())  // Forces the child view to be recreated when the user account changes

                case .initializing:
                    SessionTransitionScreen()

                case .restoring:
                    // This is needed to cover the delay between app launch and SDK returning an existing session
                    // otherwise we would be flashing the welcome screen
                    EmptyView()
                }
            }
            .transition(.opacity)
        }
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
                }
            )
        case .pinRequired(let errorFromLatestAttempt):
            PINLockScreen(
                error: .constant(errorFromLatestAttempt.map(PINAuthenticationError.custom))
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

    private func observeAndDisplayAppContextErrors() {
        Task { @MainActor in
            for await error in AppContext.shared.errors.values {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }

    private func submitBackgroundTask() {
        Task {
            await recurringBackgroundTaskScheduler.submit()
        }
    }
}

private struct SessionTransitionScreen: View {
    private let userDefaultsWithPromptsDisabled: UserDefaults = {
        let userDefaults = UserDefaults(suiteName: "transition")!
        userDefaults[.hasSeenAlphaOnboarding] = true
        userDefaults[.notificationAuthorizationRequestDates] = [.now]
        userDefaults[.hasSeenOnboardingUpsell] = true
        return userDefaults
    }()

    var body: some View {
        ZStack {
            fakeMailboxScreen

            progressView
        }
    }

    private var fakeMailboxScreen: some View {
        MailboxScreen(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: .initialState,
            notificationAuthorizationStore: .init(userDefaults: userDefaultsWithPromptsDisabled),
            userSession: .dummy,
            userDefaults: userDefaultsWithPromptsDisabled,
            draftPresenter: .dummy()
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
