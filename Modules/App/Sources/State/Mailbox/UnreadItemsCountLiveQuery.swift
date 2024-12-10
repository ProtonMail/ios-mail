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
        let liveQueryCallback = LiveQueryCallbackWrapper()
        liveQueryCallback.delegate = { [weak self] in
            guard let self else { return }

            Task {
                await self.emitDataIfAvailable()
            }
        }

        switch await mailbox.watchUnreadCount(callback: liveQueryCallback) {
        case .ok(let watchHandle):
            self.watchHandle = watchHandle
            await emitDataIfAvailable()
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
        }
    }

    // MARK: - Private

    private func emitDataIfAvailable() async {
        switch await mailbox.unreadCount() {
        case .ok(let unreadItemsCount):
            await dataUpdate(unreadItemsCount)
        case .error(let error):
            AppLogger.log(error: error, category: .mailbox)
        }
    }
}
