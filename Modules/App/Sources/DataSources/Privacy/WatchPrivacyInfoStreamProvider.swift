// Copyright (c) 2026 Proton Technologies AG
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

import proton_app_uniffi

struct WatchPrivacyInfoStreamProvider {
    private let userSession: MailUserSession
    private let actions: WatchPrivacyInfoStreamActions

    init(userSession: MailUserSession, actions: WatchPrivacyInfoStreamActions) {
        self.userSession = userSession
        self.actions = actions
    }

    func stream(for messageId: ID) async throws -> any AsyncWatchingStream {
        try await actions.stream(userSession, messageId)
    }
}

struct WatchPrivacyInfoStreamActions: Sendable {
    let stream: @Sendable (_ session: MailUserSession, _ messageId: ID) async throws -> any AsyncWatchingStream
}

extension WatchPrivacyInfoStreamActions {
    static var productionInstance: Self {
        .init { session, messageId in
            try await watchPrivacyInfoStream(session: session, messageId: messageId).get()
        }
    }
}
