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

import proton_mail_uniffi

protocol MessageBodyDataSource {
    @MainActor
    func messageBody(for messageId: PMLocalMessageId) async -> String?
}

final class MessageBodyAPIDataSource: Sendable, MessageBodyDataSource {
    static let shared: MessageBodyAPIDataSource = .init()
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func messageBody(for messageId: PMLocalMessageId) async -> String? {
        do {
            guard let userSession = dependencies.appContext.activeUserSession else { return nil }
            let mailbox = try await Mailbox.inbox(ctx: userSession)
            return try await mailbox.messageBody(id: messageId).body()
        }
        catch {
            return nil
        }
    }
}

extension MessageBodyAPIDataSource {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
