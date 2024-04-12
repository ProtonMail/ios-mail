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

    private var _mailContext: MailSession!
    private let userSession: UserSession = UserSession()
    private let dependencies: AppContext.Dependencies
    private var cancellables = Set<AnyCancellable>()

    private var mailContext: MailSession {
        guard let mailContext = _mailContext else {
            fatalError("AppSession.start was not called")
        }
        return mailContext
    }

    @Published private(set) var hasActiveUser: Bool = false

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
        _mailContext = try MailSession.create(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            logDir: cachePath,
            logDebug: true,
            keyChain: dependencies.keychain,
            apiEnvConfig: nil,
            networkCallback: dependencies.networkStatus
        )

        if let _ = try mailContext.storedSessions().first {
            hasActiveUser = true
        }
    }

    func userContextForActiveSession() async throws -> MailUserSession? {
        try await userSession.activeSession(from: mailContext)
    }
}

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
    case cacheDirectoryNotAccessible
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
                guard let mailContext = self?.mailContext, let userSession = self?.userSession else { return }
                async let mailUserSession = try await userSession.activeSession(from: mailContext)

                /**
                 For now, event loop calls can't be run in parallel so we flush any action from the queue first.
                 Once this is not a limitation, we should run actions right after the actionis triggered by calling `executePendingAction()`
                 */
                AppLogger.log(message: "execute pending actions", category: .rustLibrary)
                try await mailUserSession?.executePendingActions()

                AppLogger.log(message: "poll events", category: .rustLibrary)
                try await mailUserSession?.pollEvents()
            } catch {
                AppLogger.log(error: error, category: .rustLibrary)
            }
        }
    }
}

extension AppContext: SessionProvider {

    @MainActor
    func login(email: String, password: String) async throws {
        let flow = try mailContext.newLoginFlow(cb: SessionDelegate.shared)
        try await flow.login(email: email, password: password)
        let newUserContext = try flow.toUserContext()
        try await userSession.udpateActiveSession(newUserContext)
        hasActiveUser = true
    }

    @MainActor
    func logoutActiveUserSession() async throws {
        try await userSession.activeSession(from: mailContext)?.logout()
        hasActiveUser = false
        try await userSession.udpateActiveSession(nil)
    }
}
