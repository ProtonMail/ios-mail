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

import Foundation
import proton_app_uniffi
import UserNotifications

struct AppIconBadgeService {
    private let notificationCenter: UNUserNotificationCenter = .current()
    private let inboxUnreadCount: () async throws -> UInt64

    init(inboxUnreadCount: @escaping () async throws -> UInt64) {
        self.inboxUnreadCount = inboxUnreadCount
    }

    init(appContext: AppContext) {
        self.init {
            guard let userSession = appContext.sessionState.userSession else {
                return 0
            }

            let inbox = try await newInboxMailbox(ctx: userSession).get()
            return try await inbox.unreadCount().get()
        }
    }
}

// we're only requesting authorization on app launch because the OS won't display a badge on the icon without it
// we're doing it like this per Product team instruction, and this must be removed and redone before GA
// ultimately we'll be going for
// https://protonag.atlassian.net/wiki/spaces/INBOX/pages/199098370/Improved+notification+permission
extension AppIconBadgeService: ApplicationServiceSetUp {
    func setUpService() {
        notificationCenter.requestAuthorization(options: [.badge]) { _, error in
            if let error {
                AppLogger.log(error: error)
            }
        }
    }
}

extension AppIconBadgeService: ApplicationServiceDidEnterBackground {
    func enterBackgroundService() {
        Task {
            await enterBackgroundServiceAsync()
        }
    }

    func enterBackgroundServiceAsync() async {
        do {
            let unreadCount = Int(try await inboxUnreadCount())
            try await notificationCenter.setBadgeCount(unreadCount)
        } catch {
            AppLogger.log(error: error)
        }
    }
}
