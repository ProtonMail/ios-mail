// Copyright (c) 2025 Proton Technologies AG
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

import Foundation
import InboxCore
import InboxKeychain
import proton_app_uniffi

public actor MailUserSessionFactory: Sendable {
    typealias CreateMailSession = (MailSessionParams, KeychainSDKWrapper) -> CreateMailIosExtensionSessionResult

    private let createMailSession: CreateMailSession
    private var cachedMailSession: MailSession?

    public init() {
        self.init(createMailSession: createMailIosExtensionSession)
    }

    init(createMailSession: @escaping CreateMailSession) {
        self.createMailSession = createMailSession
    }

    public func make() async throws -> MailUserSession {
        let mailSession: MailSession

        if let cachedMailSession = cachedMailSession {
            mailSession = cachedMailSession
        } else {
            let params = MailSessionParamsFactory.make(appConfig: .default)
            let keychain = KeychainSDKWrapper()
            mailSession = try createMailSession(params, keychain).get()
            cachedMailSession = mailSession
        }

        guard let primaryAccount = try await mailSession.getPrimaryAccount().get() else {
            throw MailUserSessionFactoryError.notSignedIn
        }

        let storedSessions = try await mailSession.getAccountSessions(account: primaryAccount).get()

        guard let storedSession = storedSessions.first else {
            throw MailUserSessionFactoryError.notSignedIn
        }

        return try await mailSession.userContextFromSession(session: storedSession).get()
    }
}

enum MailUserSessionFactoryError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            L10n.needToSignIn.string
        }
    }
}
