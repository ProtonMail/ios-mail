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

import InboxCore
import InboxKeychain
import proton_app_uniffi

/*
 This type exists because even though `NotificationService` is actually deinitialized every time after it finishes processing a notification,
 the `MailSession` created on the Rust side remains in memory and needs to be reused.

 Attempting to create a new one will trigger a panic - a SetGlobalDefaultError related to the logger in the SDK.
 */
enum ProcessWideMailSessionCache {
    private static var cachedMailSession: MailSession?

    static func prepareMailSession() throws -> MailSession {
        if let cachedMailSession = cachedMailSession {
            return cachedMailSession
        } else {
            let params = MailSessionParamsFactory.make(appConfig: .default)
            let mailSessionResult = createMailSession(params: params, keyChain: KeychainSDKWrapper())

            switch mailSessionResult {
            case .ok(let mailSession):
                cachedMailSession = mailSession
                return mailSession
            case .error(let userSessionError):
                throw userSessionError
            }
        }
    }
}

extension UserSessionError: Error {}
