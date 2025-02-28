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

    var hasActiveUser: Bool {
        if case .activeSession = sessionState {
            return true
        }
        return false
    }

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    private func start() throws {
        AppLogger.log(message: "AppContext.start", category: .appLifeCycle)

        let appConfig = dependencies.appConfigService.appConfig

        userDefaults = dependencies.userDefaults
        userDefaultsCleaner = .init(userDefaults: userDefaults)
        
        let params = MailSessionParamsFactory.make(appConfig: appConfig)

        _mailSession = try createMailSession(
            params: params,
            keyChain: dependencies.keychain
        ).get()
        AppLogger.log(message: "MailSession init | \(Bundle.main.appVersion)", category: .rustLibrary)

        accountAuthCoordinator = AccountAuthCoordinator(appContext: _mailSession, authDelegate: self)
        setupAccountBindings()

        if let currentSession = accountAuthCoordinator.primaryAccountSignedInSession() {
            switch mailSession.userContextFromSession(session: currentSession) {
            case .ok(let newUserSession):
                withAnimation { sessionState = .activeSession(session: newUserSession) }
            case .error(let error):
                throw error
            }
        }
    }
}

extension AppContext: AccountAuthDelegate {
    func accountSessionInitialization(storedSession: StoredSession) async throws {
        try await initializeMailUserSession(session: storedSession)
    }

    func setupAccountBindings() {
        accountAuthCoordinator.$primaryAccountSession
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSession in
                guard let self else { return }
                guard let primaryAccountSession = newSession else {
                    userDefaultsCleaner.cleanUp()
                    withAnimation { self.sessionState = .noSession }
                    return
                }
                // Needed for a smoother UI transition.
                // Gives time to the AccountSwitcher for dismissing.
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.sessionChangeDelay) {
                    withAnimation { self.sessionState = .activeSessionTransition }
                    DispatchQueue.main.async {
                        self.setupActiveUserSession(session: primaryAccountSession)
                        self.pollEvents()
                    }
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func initializeMailUserSession(session: StoredSession) async throws {
        let newUserSession = try mailSession.userContextFromSession(session: session).get()
        try await newUserSession.initialize(cb: UserContextInitializationDelegate.shared).get()
    }

    @MainActor
    private func setupActiveUserSession(session: StoredSession) {
        switch mailSession.userContextFromSession(session: session) {
        case .ok(let newUserSession):
            withAnimation { self.sessionState = .activeSession(session: newUserSession) }
        case .error(let error):
            AppLogger.log(error: error, category: .userSessions)
        }
    }
}

extension AppContext {

    struct Dependencies {
        let keychain: OsKeyChain = KeychainSDKWrapper()
        let appConfigService: AppConfigService = AppConfigService.shared
        let userDefaults: UserDefaults = .standard
    }
}

final class UserContextInitializationDelegate: MailUserSessionInitializationCallback, Sendable {
    static let shared = UserContextInitializationDelegate()

    func onStage(stage: proton_app_uniffi.MailUserSessionInitializationStage) {
        AppLogger.logTemporarily(message: "MailUserSessionInitializationStage.onStage stage: \(stage)")
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

extension AppContext: EventLoopProvider {

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
            try await userSession.pollEvents().get()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }
}
