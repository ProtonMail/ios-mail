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
import proton_app_uniffi

final class AppContext: Sendable, ObservableObject {
    static let shared: AppContext = .init()

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
        guard let applicationSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AppContextError.applicationSupportDirectoryNotAccessible
        }
        guard let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw AppContextError.cacheDirectoryNotAccessible
        }

        guard let appConfig = dependencies.appConfigService.appConfig else {
            throw AppContextError.appConfigNotDefined
        }

        userDefaults = dependencies.userDefaults
        userDefaultsCleaner = .init(userDefaults: userDefaults)

        // TODO: exclude application support from iCloud backup

        let applicationSupportPath = applicationSupportFolder.path()
        let cachePath = cacheFolder.path()
        AppLogger.logTemporarily(message: "path: \(cacheFolder)")
        
        let params = MailSessionParams(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            mailCacheDir: cachePath, 
            mailCacheSize: .oneHundredMBInBytes,
            logDir: cachePath,
            logDebug: false,
            apiEnvConfig: appConfig.apiEnvConfig
        )

        _mailSession = try createMailSession(
            params: params,
            keyChain: dependencies.keychain,
            networkCallback: dependencies.networkStatus
        ).get()
        AppLogger.log(message: "MailSession init | \(Bundle.main.appVersion)", category: .rustLibrary)

        accountAuthCoordinator = AccountAuthCoordinator(appContext: _mailSession, authDelegate: self)
        setupAccountBindings()

        if let currentSession = accountAuthCoordinator.primaryAccountSignedInSession() {
            switch mailSession.userContextFromSession(session: currentSession) {
            case .ok(let newUserSession):
                sessionState = .activeSession(session: newUserSession)
            case .error(let error):
                throw error
            }
        }
    }
}

extension AppContext: AccountAuthDelegate {
    func accountSessionInitialization(storedSession: StoredSession) async {
        await initializeMailUserSession(session: storedSession)
    }

    func setupAccountBindings() {
        accountAuthCoordinator.$primaryAccountSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSession in
                guard let self else { return }
                guard let primaryAccountSession = newSession else {
                    userDefaultsCleaner.cleanUp()
                    self.sessionState = .noSession
                    return
                }
                self.sessionState = .activeSessionTransition
                DispatchQueue.main.async {
                    self.setupActiveUserSession(session: primaryAccountSession)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func initializeMailUserSession(session: StoredSession) async {
        do {
            switch mailSession.userContextFromSession(session: session) {
            case .ok(let newUserSession):
                try await newUserSession.initialize(cb: UserContextInitializationDelegate.shared).get()
            case .error(let error):
                throw error
            }
        } catch {
            AppLogger.log(error: error, category: .userSessions)
        }
    }

    @MainActor
    private func setupActiveUserSession(session: StoredSession) {
        switch mailSession.userContextFromSession(session: session) {
        case .ok(let newUserSession):
            self.sessionState = .activeSession(session: newUserSession)
        case .error(let error):
            AppLogger.log(error: error, category: .userSessions)
        }
    }
}

extension AppContext {

    struct Dependencies {
        let keychain: OsKeyChain = KeychainSDKWrapper()
        let networkStatus: NetworkStatusChanged = NetworkStatusManager.shared
        let appConfigService: AppConfigService = AppConfigService.shared
        let userDefaults: UserDefaults = .standard
    }
}

enum AppContextError: Error {
    case applicationSupportDirectoryNotAccessible
    case cacheDirectoryNotAccessible
    case appConfigNotDefined
}

final class NetworkStatusManager: NetworkStatusChanged, Sendable {
    static let shared = NetworkStatusManager()

    func onNetworkStatusChanged(online: Bool) {
        AppLogger.logTemporarily(message: "onNetworkStatusChanged online: \(online)")
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

            /**
             For now, event loop calls can't be run in parallel so we flush any action from the queue first.
             Once this is not a limitation, we should run actions right after the actionis triggered by calling `executePendingAction()`
             */
            AppLogger.log(message: "execute pending actions", category: .rustLibrary)
            try await userSession.executePendingActions().get()

            AppLogger.log(message: "poll events", category: .rustLibrary)
            try await userSession.pollEvents().get()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }
}

private extension UInt32 {
    static let oneHundredMBInBytes: Self = 100 * 1_024 * 1_024
}
