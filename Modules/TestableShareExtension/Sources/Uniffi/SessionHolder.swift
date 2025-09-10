//
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

import AccountChallenge
import InboxCore
import InboxKeychain
import proton_app_uniffi

/**
 The purpose of this class is to guarantee that MailSession and the primary MailUserSession are:
 - only created once
 - retained for the entire lifetime of the Share extension
 */
final class SessionHolder {
    typealias MakeMailSession = (MailSessionParams, OsKeyChain, ChallengeNotifier?, DeviceInfoProvider?) throws -> MailSessionProtocol

    private let apiEnvId: ApiEnvId
    private let makeMailSession: MakeMailSession

    private var cachedMailSession: MailSessionProtocol?
    private var cachedUserSession: MailUserSession?

    init(apiEnvId: ApiEnvId, makeMailSession: @escaping MakeMailSession) {
        self.apiEnvId = apiEnvId
        self.makeMailSession = makeMailSession
    }

    func mailSession() throws -> MailSessionProtocol {
        if let cachedMailSession {
            return cachedMailSession
        } else {
            let apiConfig = ApiConfig(userAgent: "mail tests", envId: apiEnvId)
            let params = MailSessionParamsFactory.make(origin: .iosShareExt, apiConfig: apiConfig)
            let newMailSession = try makeMailSession(params, KeychainSDKWrapper(), nil, ChallengePayloadProvider())
            cachedMailSession = newMailSession
            return newMailSession
        }
    }

    func primaryUserSession() async throws -> MailUserSession {
        if let cachedUserSession {
            return cachedUserSession
        } else {
            let newUserSession = try await mailSession().toPrimaryUserSession().get()
            cachedUserSession = newUserSession
            return newUserSession
        }
    }
}
