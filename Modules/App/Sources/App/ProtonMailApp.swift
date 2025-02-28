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

import InboxCoreUI
import proton_app_uniffi
import SwiftUI

@main
struct ProtonMailApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    // declaration of state objects
    private let appUIStateStore = AppUIStateStore()
    private let toastStateStore = ToastStateStore(initialState: .initial)

    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                RootView(appContext: .shared)
                    .environment(\.mainWindowSize, proxy.size)
                    .environmentObject(appUIStateStore)
                    .environmentObject(toastStateStore)
            }
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            // scenePhase contains an aggregate phase for all scenes
            if newValue == .active {
                AppLifeCycle.shared.allScenesDidBecomeActive()
            } else if newValue == .background {
                AppLifeCycle.shared.allScenesDidEnterBackground()
            }
        })
    }
}

private struct RootView: View {
    @EnvironmentObject private var sceneDelegate: SceneDelegate
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
                    appContext
                        .accountAuthCoordinator
                        .accountView()

                case .activeSession(let activeUserSession):
                    HomeScreen(
                        appContext: appContext,
                        userSession: activeUserSession,
                        toastStateStore: toastStateStore
                    )
                    .id(activeUserSession.userId()) // Forces the child view to be recreated when the user account changes

                case .activeSessionTransition:
                    EmptyView()
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut, value: appContext.sessionState)
    }

    private func submitBackgroundTask() {
        Task {
            await recurringBackgroundTaskScheduler.submit()
        }
    }
}
