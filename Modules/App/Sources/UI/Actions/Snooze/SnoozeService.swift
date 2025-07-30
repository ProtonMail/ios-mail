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

import proton_app_uniffi

protocol SnoozeServiceProtocol {
    func availableSnoozeActionsForConversation(weekStart: NonDefaultWeekStart, id: Id) -> AvailableSnoozeActionsForConversationResult
    func snoozeConversations(ids: [Id], snoozeTime: UnixTimestamp) -> SnoozeConversationsResult
    func unsnoozeConversations(ids: [Id]) -> UnsnoozeConversationsResult
}

class SnoozeService: SnoozeServiceProtocol {
    private let mailUserSession: () -> MailUserSession

    init(mailUserSession: @escaping () -> MailUserSession) {
        self.mailUserSession = mailUserSession
    }

    func availableSnoozeActionsForConversation(
        weekStart: NonDefaultWeekStart,
        id: Id
    ) -> AvailableSnoozeActionsForConversationResult {
        .ok(
            .init(
                options: [.custom, .tomorrow(1753869563), .laterThisWeek(1753869563), .thisWeekend(1753869563)],
                showUnsnooze: true)
        )
    }

    func snoozeConversations(ids: [Id], snoozeTime: UnixTimestamp) -> SnoozeConversationsResult {
        ProtonMail.snoozeConversations(session: mailUserSession(), ids: ids, snoozeTime: snoozeTime)
    }

    func unsnoozeConversations(ids: [Id]) -> UnsnoozeConversationsResult {
        ProtonMail.unsnoozeConversations(session: mailUserSession(), ids: ids)
    }
}
