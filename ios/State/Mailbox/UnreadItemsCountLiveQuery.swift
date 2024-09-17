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

final class UnreadItemsCountLiveQuery: @unchecked Sendable {
    private let mailbox: Mailbox
    private let dataUpdate: (UInt64) async -> Void
    private var watchHandle: WatchHandle?

    init(mailbox: Mailbox, dataUpdate: @escaping (UInt64) async -> Void) {
        self.mailbox = mailbox
        self.dataUpdate = dataUpdate
    }

    func setUpLiveQuery() async {
        do {
            let delegate = PMMailboxLiveQueryUpdatedCallback { [weak self] in
                guard let unwrappedSelf = self else { return }

                Task {
                    await unwrappedSelf.emitDataIfAvailable()
                }
            }

            watchHandle = try await mailbox.watchUnreadCount(callback: delegate)
            await emitDataIfAvailable()
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    // MARK: - LiveQueryCallback

    func onUpdate() {
        Task {
            await emitDataIfAvailable()
        }
    }

    // MARK: - Private

    private func emitDataIfAvailable() async {
        do {
            let unreadItemsCount = try await mailbox.unreadCount()
            await dataUpdate(unreadItemsCount)
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }
}
