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

protocol AppContextService {
    init(dependencies: AppContext.Dependencies)
    func login(email: String, password: String) async throws
    func logoutActiveUserSession() async throws
    func userContextForActiveSession() async throws -> MailUserContext?
}

final class AppContext: AppContextService, Sendable {
    static let shared: AppContext = .init()

    private var _mailContext: MailContext!
    private var activeUserContext: MailUserContext? {
        didSet {
            let hasActiveUser = activeUserContext != nil
            let msg = hasActiveUser ? "new activeUserContext" : "deleted activeUserContext"
            AppLogger.log(message: msg, category: .userSessions)
            activeUserStatusPublisher.send(hasActiveUser ? .hasActiveUser : .noActiveUser)
        }
    }
    private let dependencies: AppContext.Dependencies

    private var mailContext: MailContext {
        guard let mailContext = _mailContext else {
            fatalError("AppSession.start was not called")
        }
        return mailContext
    }

    private(set) var appState: AppState
    private(set) var activeUserStatusPublisher = CurrentValueSubject<ActiveUserStatus, Never>(.noActiveUser)

    var activeSession: StoredSession? {
        do {
            return try mailContext.storedSessions().first
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
            return nil
        }
    }

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
        self.appState = AppState()
    }

    private func start() throws {
        AppLogger.log(message: "AppContext.start", category: .appLifeCycle)
        guard let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AppContextError.applicationSupportDirectoryNotAccessible
        }

        // TODO: exclude application support from iCloud backup

        let applicationSupportPath = applicationSupport.path()
        _mailContext = try MailContext(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            logDir: applicationSupportPath,
            logDebug: true,
            keyChain: dependencies.keychain,
            networkCallback: dependencies.networkStatus
        )

        appState.appContext = self
        Task {
            await refreshAppState()
        }
    }

    private func updateUserContext(_ userContext: MailUserContext?) async throws {
        try await userContext?.initialize(cb: UserContextInitializationDelegate.shared)
        activeUserContext = userContext
        await refreshAppState()
    }

    func login(email: String, password: String) async throws {
        let flow = try mailContext.newLoginFlow(cb: SessionDelegate.shared)
        try await flow.login(email: email, password: password)
        let newUserContext = try flow.toUserContext()
        try await updateUserContext(newUserContext)
    }

    func logoutActiveUserSession() async throws {
        try await activeUserContext?.logout()
        try await updateUserContext(nil)
    }

    func userContextForActiveSession() async throws -> MailUserContext? {
        if let userContext = activeUserContext {
            return userContext
        }
        guard let activeSession else { return nil }
        let newUserContext = try mailContext.userContextFromSession(session: activeSession, cb: SessionDelegate.shared)
        try await updateUserContext(newUserContext)
        return activeUserContext
    }

    func refreshAppState() async {
        await appState.refresh()
    }
}

extension AppContext: ActiveUserStatusProvider {}

extension AppContext {

    struct Dependencies {
        let fileManager: FileManager = .default
        let keychain: OsKeyChain = Keychain.shared
        let networkStatus: NetworkStatusChanged = NetworkStatusManager.shared
    }
}

extension AppContext {
    enum Keys: String {
        case session
    }
}

enum AppContextError: Error {
    case applicationSupportDirectoryNotAccessible
}

final class Keychain: OsKeyChain {
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

final class NetworkStatusManager: NetworkStatusChanged {
    static let shared = NetworkStatusManager()

    func onNetworkStatusChanged(online: Bool) {
        AppLogger.logTemporarily(message: "onNetworkStatusChanged online: \(online)")
    }
}

final class SessionDelegate: SessionCallback {
    static let shared = SessionDelegate()

    func onSessionRefresh() {
        AppLogger.logTemporarily(message: "onSessionRefresh")
    }

    func onSessionDeleted() {
        AppLogger.logTemporarily(message: "onSessionDeleted")
    }

    func onRefreshFailed(e: proton_mail_uniffi.SessionError) {
        AppLogger.logTemporarily(message: "onRefreshFailed error: \(e)")
    }

    func onError(err: proton_mail_uniffi.SessionError) {
        AppLogger.logTemporarily(message: "onError error: \(err)")
    }
}

final class UserContextInitializationDelegate: MailUserContextInitializationCallback {
    static let shared = UserContextInitializationDelegate()

    func onStage(stage: proton_mail_uniffi.MailUserContextInitializationStage) {
        AppLogger.logTemporarily(message: "UserContextInitializationDelegate.onStage stage: \(stage)")
    }

    func onStageErr(stage: proton_mail_uniffi.MailUserContextInitializationStage, err: proton_mail_uniffi.MailContextError) {
        AppLogger.logTemporarily(message: "UserContextInitializationDelegate.onStageError stage: \(stage) error: \(err)")
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
        Task {
            AppLogger.log(message: "poll events", category: .rustLibrary)
            do {
                try await activeUserContext?.pollEvents()
            } catch {
                AppLogger.log(error: error, category: .rustLibrary)
            }
        }
    }
}
