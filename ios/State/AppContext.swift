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
import Foundation
import proton_mail_uniffi

final class AppContext: Sendable, ObservableObject {
    static let shared: AppContext = .init()

    private var _mailSession: MailSession!
    private let dependencies: AppContext.Dependencies
    private var cancellables = Set<AnyCancellable>()

    private var mailSession: MailSession {
        guard let mailContext = _mailSession else {
            fatalError("AppSession.start was not called")
        }
        return mailContext
    }

    @Published private(set) var activeUserSession: MailUserSession?
    var hasActiveUser: Bool {
        activeUserSession != nil
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

        // TODO: exclude application support from iCloud backup

        let applicationSupportPath = applicationSupportFolder.path()
        let cachePath = cacheFolder.path()
        AppLogger.logTemporarily(message: "path: \(cacheFolder)")
        
        let apiEnvConfig = dependencies.apiEnvConfigService.getConfiguration()

        let params = MailSessionParams(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            mailCacheDir: cachePath,
            logDir: cachePath,
            logDebug: true,
            apiEnvConfig: apiEnvConfig
        )

        _mailSession = try MailSession.create(
            params: params,
            keyChain: dependencies.keychain,
            networkCallback: dependencies.networkStatus
        )

        if let storedSession = try mailSession.storedSessions().first {
            activeUserSession = try mailSession.userContextFromSession(
                session: storedSession,
                sessionCb: SessionDelegate.shared
            )
        }
    }
}

extension AppContext {

    struct Dependencies {
        let fileManager: FileManager = .default
        let keychain: OsKeyChain = Keychain.shared
        let networkStatus: NetworkStatusChanged = NetworkStatusManager.shared
        let apiEnvConfigService: ApiEnvConfigService = ApiEnvConfigService.shared
    }
}

extension AppContext {
    enum Keys: String {
        case session
    }
}

enum AppContextError: Error {
    case applicationSupportDirectoryNotAccessible
    case cacheDirectoryNotAccessible
}

final class Keychain: OsKeyChain, Sendable {
    static let shared = Keychain()

    // TODO: use the keychain

    func store(key: String) throws {
        AppLogger.logTemporarily(message: "KeychainWrapper.store key:\(key)")
        UserDefaults.standard.setValue(key, forKey: AppContext.Keys.session.rawValue)
    }

    func delete() throws {
        let existingKey: String = (try? get()) ?? ""
        AppLogger.logTemporarily(message: "KeychainWrapper.delete, existing value: \(existingKey)")
        UserDefaults.standard.removeObject(forKey: AppContext.Keys.session.rawValue)
    }

    func get() throws -> String? {
        let value = UserDefaults.standard.string(forKey: AppContext.Keys.session.rawValue)
        AppLogger.logTemporarily(message: "KeychainWrapper.get \(value ?? "-")")
        return value
    }
}

final class NetworkStatusManager: NetworkStatusChanged, Sendable {
    static let shared = NetworkStatusManager()

    func onNetworkStatusChanged(online: Bool) {
        AppLogger.logTemporarily(message: "onNetworkStatusChanged online: \(online)")
    }
}

final class SessionDelegate: SessionCallback, Sendable {
    static let shared = SessionDelegate()

    func onSessionRefresh() {
        AppLogger.logTemporarily(message: "onSessionRefresh", category: .userSessions)
    }

    func onSessionDeleted() {
        AppLogger.logTemporarily(message: "onSessionDeleted", category: .userSessions)
    }

    func onRefreshFailed(e: proton_mail_uniffi.SessionError) {
        AppLogger.logTemporarily(message: "onRefreshFailed error: \(e)", category: .userSessions)
    }

    func onError(err: proton_mail_uniffi.SessionError) {
        AppLogger.logTemporarily(message: "onError error: \(err)", category: .userSessions)
    }
}

final class UserContextInitializationDelegate: MailUserSessionInitializationCallback, Sendable {
    static let shared = UserContextInitializationDelegate()

    func onStage(stage: proton_mail_uniffi.MailUserSessionInitializationStage) {
        AppLogger.logTemporarily(message: "MailUserSessionInitializationStage.onStage stage: \(stage)")
    }

    func onStageErr(stage: proton_mail_uniffi.MailUserSessionInitializationStage, err: proton_mail_uniffi.MailSessionError) {
        AppLogger.logTemporarily(message: "MailUserSessionInitializationStage.onStageError stage: \(stage) error: \(err)")
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
            do {
                guard let mailUserSession = self?.activeUserSession else {
                    AppLogger.log(message: "poll events called but no active session found", category: .userSessions)
                    return
                }

                /**
                 For now, event loop calls can't be run in parallel so we flush any action from the queue first.
                 Once this is not a limitation, we should run actions right after the actionis triggered by calling `executePendingAction()`
                 */
                AppLogger.log(message: "execute pending actions", category: .rustLibrary)
                try await mailUserSession.executePendingActions()

                AppLogger.log(message: "poll events", category: .rustLibrary)
                try await mailUserSession.pollEvents()
            } catch {
                AppLogger.log(error: error, category: .rustLibrary)
            }
        }
    }
}

extension AppContext: SessionProvider {

    @MainActor
    func login(email: String, password: String) async throws {
        let flow = try mailSession.newLoginFlow(cb: SessionDelegate.shared)
        try await flow.login(email: email, password: password)
        let newUserSession = try flow.toUserContext()
        try await newUserSession.initialize(cb: UserContextInitializationDelegate.shared)
        activeUserSession = newUserSession
    }

    @MainActor
    func logoutActiveUserSession() async throws {
        try await activeUserSession?.logout()
        activeUserSession = nil
    }
}
