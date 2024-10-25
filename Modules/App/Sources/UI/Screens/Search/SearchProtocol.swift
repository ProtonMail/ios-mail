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

import proton_app_uniffi

protocol SearchProtocol: Sendable {

    func paginateSearch(
      session: MailUserSession,
      options: SearchOptions,
      callback: LiveQueryCallback
    ) async throws -> SearchPaginator
}

struct SearchOptions {
    let query: String
}

protocol SearchPaginator {
    func hasNextPage() -> Bool
    func nextPage() async throws -> [Message]
    func reload() async throws -> [Message]
    func resultCount() -> UInt32
    func handle() -> WatchHandle
}

// SDK Mocks

struct MockSearchPaginator: SearchPaginator {
    private let messagePaginator: MessagePaginator
    let callback: LiveQueryCallback

    init(callback: LiveQueryCallback) async {
        self.messagePaginator = try! await paginateMessagesForLabel(
            session: AppContext.shared.userSession,
            labelId: .init(value: [1,23].randomElement()!),
            callback: callback
        )
        self.callback = callback
    }

    func hasNextPage() -> Bool {
        messagePaginator.hasNextPage()
    }

    func nextPage() async throws -> [Message] {
        try await messagePaginator.nextPage()
    }

    func reload() async throws -> [Message] {
        try await messagePaginator.reload()
    }

    func resultCount() -> UInt32 {
        messagePaginator.resultCount()
    }

    func handle() -> WatchHandle {
        messagePaginator.handle()
    }
}
