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

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("*** SCENE ENTERED FOREGROUND")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("*** SCENE ENTERED BACKGROUND")

        openDB()
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("*** APP ENTERED FOREGROUND")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("*** APP ENTERED BACKGROUND")
    }

}

@main
struct ProtonMailApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ZStack {
                Text("Testing app")
            }
        }
    }
}

import SQLite3

var DB: OpaquePointer? = nil;

func openDB() {
    let cachesURL = FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!

    // 2. Define your subdirectory
    let myDirURL = cachesURL.appendingPathComponent("MyCacheDir", isDirectory: true)

    // 3. Create the directory (if it doesn't already exist)
    try! FileManager.default.createDirectory(
        at: myDirURL,
        withIntermediateDirectories: true,
        attributes: nil
    )

    // 4. Define the text file URL
    let fileURL = myDirURL.appendingPathComponent("sqlite.db")

    if sqlite3_open(fileURL.path(), &DB) != SQLITE_OK {
        print("Failed to open db")
        return
    }

    if sqlite3_exec(DB,"PRAGMA JOURNAL_MODE=WAL", nil, nil,nil) != SQLITE_OK {
        print("Failed to create table")
        return
    }


    if sqlite3_exec(DB,"CREATE TABLE IF NOT EXISTS foo(id INTEGER PRIMARY KEY AUTOINCREMENT, bar TEXT NOT NULL DEFAULT '')", nil, nil,nil) != SQLITE_OK {
        print("Failed to create table")
        return
    }

    if sqlite3_exec(DB,"INSERT INTO foo (bar) VALUES('bar')", nil, nil,nil) != SQLITE_OK {
        print("Failed to insert record")
        return
    }


    if sqlite3_exec(DB,"BEGIN TRANSACTION IMMEDIATE", nil,nil,nil) != SQLITE_OK {
        print("Failed to begin transaction")
    } else {
        print("Transaction started")
    }

    if sqlite3_exec(DB,"INSERT INTO foo (bar) VALUES('foobar')", nil, nil,nil) != SQLITE_OK {
        print("Failed to insert record tx")
        return
    }

}

struct ProtonMailApp_2: App {
    @UIApplicationDelegateAdaptor(AppDelegate2.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase, { oldValue, newValue in
            // scenePhase contains an aggregate phase for all scenes
            print("*** SCENE PHASE HAS CHANGED, OLD: \(oldValue), NEW: \(newValue)")
            if newValue == .active {
                AppLifeCycle.shared.allScenesDidBecomeActive()
            } else if newValue == .background {
                AppLifeCycle.shared.allScenesDidEnterBackground()
            }
        })
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
//                sceneDelegate.toastStateStore = toastStateStore
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
