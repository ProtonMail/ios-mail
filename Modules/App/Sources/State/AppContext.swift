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

import AccountChallenge
import AccountLogin
import Combine
import Foundation
import InboxCore
import InboxKeychain
import proton_app_uniffi
import SwiftUI

final class AppContext: Sendable, ObservableObject {
    static let shared: AppContext = .init()

    private enum Constants {
        static let sessionChangeDelay = 0.1
    }

    var userSession: MailUserSession {
        guard let userSession = sessionState.userSession else {
            fatalError("Can not find active session.")
        }

        return userSession
    }

    var mailSession: MailSession {
        guard let mailContext = _mailSession else {
            fatalError("AppSession.start was not called")
        }
        return mailContext
    }

    private var _mailSession: MailSession!
    private let dependencies: AppContext.Dependencies
    private var cancellables = Set<AnyCancellable>()

    private(set) var userDefaults: UserDefaults!
    private var userDefaultsCleaner: UserDefaultsCleaner!

    @Published private(set) var sessionState = SessionState.noSession

    private(set) var accountAuthCoordinator: AccountAuthCoordinator!
    private(set) var accountChallengeCoordinator: AccountChallengeCoordinator!

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    @MainActor
    private func start() throws {
        AppLogger.log(message: "AppContext.start", category: .appLifeCycle)

        let apiConfig = ApiConfig.current

        userDefaults = dependencies.userDefaults
        userDefaultsCleaner = .init(userDefaults: userDefaults)

        let params = MailSessionParamsFactory.make(apiConfig: apiConfig)
        accountChallengeCoordinator = .init(apiConfigProvider: { apiConfig })

        _mailSession = try createMailSession(params: params, keyChain: dependencies.keychain, hvNotifier: accountChallengeCoordinator).get()
        _mailSession.pauseWork()
        AppLogger.log(message: "MailSession init | \(AppVersionProvider().fullVersion) | \(apiConfig.envId.domain)", category: .rustLibrary)

        accountAuthCoordinator = AccountAuthCoordinator(productName: "mail", appContext: _mailSession)
        setupAccountBindings()

        if let currentSession = accountAuthCoordinator.primaryAccountSignedInSession() {
            setupActiveUserSession(session: currentSession)
        }
    }
}

extension AppContext {
    func setupAccountBindings() {
        accountAuthCoordinator.$primaryAccountSession
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSession in
                guard let self else { return }

                userDefaults[.primaryAccountSessionId] = newSession?.sessionId()

                guard let primaryAccountSession = newSession else {
                    userDefaultsCleaner.cleanUp()
                    withAnimation { self.sessionState = .noSession }
                    return
                }
                // Needed for a smoother UI transition.
                // Gives time to the AccountSwitcher for dismissing.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.sessionChangeDelay) {
                    self.setupActiveUserSession(session: primaryAccountSession)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func setupActiveUserSession(session: StoredSession) {
        animateTransition(into: .activeSessionTransition)

        Task {
            do {
                if let newUserSession = try await self.initializeUserSession(session: session) {
                    self.animateTransition(into: .activeSession(session: newUserSession))
                }
                AppLogger.log(message: "initializeUserSession finished", category: .userSessions)
            } catch {
                AppLogger.log(error: error, category: .userSessions)
            }
        }
    }

    private func initializeUserSession(session: StoredSession) async throws -> MailUserSession? {
        while true {
            let start = ContinuousClock.now

            switch await mailSession.userContextFromSession(session: session) {
            case .ok(let newUserSession):
                return newUserSession
            case .error(.other(.network)):
                AppLogger.log(
                    message: "Failed to initialize session due to network error, will retry...",
                    category: .userSessions,
                    isError: true
                )

                let minimumTimeBetweenRetries = Duration.seconds(5)
                let earliestNextAttemptTime = start + minimumTimeBetweenRetries
                try await Task.sleep(until: earliestNextAttemptTime)
            case .error(let error):
                throw error
            }
        }

        return nil
    }

    @MainActor
    private func animateTransition(into newSessionState: SessionState) {
        withAnimation { sessionState = newSessionState }
    }
}

extension AppContext {

    struct Dependencies {
        let keychain: OsKeyChain = KeychainSDKWrapper()
        let userDefaults: UserDefaults = .appGroup
    }
}

extension AppContext: ApplicationServiceSetUp {

    func setUpService() {
        do {
            try start()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }
}

extension AppContext {

    func pollEvents() {
        Task { [weak self] in
            await self?.pollEventsAsync()
        }
    }

    func pollEventsAsync() async {
        do {
            guard let userSession = sessionState.userSession else {
                AppLogger.log(message: "poll events called but no active session found", category: .userSessions)
                return
            }
            AppLogger.log(message: "poll events", category: .rustLibrary)
            try await userSession.forceEventLoopPoll().get()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }
}
