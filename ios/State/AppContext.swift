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

    var userSession: MailUserSession {
        guard let activeUserSession = activeUserSession else {
            fatalError("Can not find active session.")
        }

        return activeUserSession
    }

    private var mailSession: MailSession {
        guard let mailContext = _mailSession else {
            fatalError("AppSession.start was not called")
        }
        return mailContext
    }

    private var _mailSession: MailSession!
    private let dependencies: AppContext.Dependencies
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var activeUserSession: MailUserSession?
    var hasActiveUser: Bool {
        activeUserSession != nil
    }

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    private func start() async throws {
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
            logDebug: true,
            apiEnvConfig: appConfig.apiEnvConfig
        )

        _mailSession = try await MailSession.create(
            params: params,
            keyChain: dependencies.keychain,
            networkCallback: dependencies.networkStatus
        )
        AppLogger.log(message: "MailSession init | \(Bundle.main.appVersion)", category: .rustLibrary)

        if let storedSession = try await mailSession.storedSessions().first {
            let session = try await mailSession.userContextFromSession(session: storedSession)
            Dispatcher.dispatchOnMain(.init { [weak self] in
                self?.activeUserSession = session
            })
        }
    }
}

extension AppContext {

    struct Dependencies {
        let fileManager: FileManager = .default
        let keychain: OsKeyChain = KeychainSDKWrapper()
        let networkStatus: NetworkStatusChanged = NetworkStatusManager.shared
        let appConfigService: AppConfigService = AppConfigService.shared
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

    func onStage(stage: proton_mail_uniffi.MailUserSessionInitializationStage) {
        AppLogger.logTemporarily(message: "MailUserSessionInitializationStage.onStage stage: \(stage)")
    }

    func onStageErr(stage: proton_mail_uniffi.MailUserSessionInitializationStage, err: proton_mail_uniffi.MailSessionError) {
        AppLogger.logTemporarily(message: "MailUserSessionInitializationStage.onStageError stage: \(stage) error: \(err)")
    }
}

extension AppContext: ApplicationServiceSetUp {
    
    func setUpService() async {
        do {
            try await start()
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
                try mailUserSession.executePendingActions()

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
        let flow = try await mailSession.newLoginFlow()
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

private extension UInt32 {
    static let oneHundredMBInBytes: Self = 100 * 1_024 * 1_024
}
