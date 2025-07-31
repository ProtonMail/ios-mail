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
    func availableSnoozeActions(for conversation: Id, systemCalendarWeekStart: NonDefaultWeekStart) -> AvailableSnoozeActionsForConversationResult
    func snooze(conversation ids: [Id], timestamp: UnixTimestamp) -> SnoozeConversationsResult
    func unsnooze(conversation ids: [Id]) -> UnsnoozeConversationsResult
}

class SnoozeService: SnoozeServiceProtocol {
    private let mailUserSession: () -> MailUserSession

    init(mailUserSession: @escaping () -> MailUserSession) {
        self.mailUserSession = mailUserSession
    }

    func availableSnoozeActions(
        for conversationID: Id,
        systemCalendarWeekStart: NonDefaultWeekStart
    ) -> AvailableSnoozeActionsForConversationResult {
        availableSnoozeActionsForConversation(
            session: mailUserSession(),
            weekStart: systemCalendarWeekStart,
            id: conversationID
        )
    }

    func snooze(conversation ids: [Id], timestamp: UnixTimestamp) -> SnoozeConversationsResult {
        snoozeConversations(session: mailUserSession(), ids: ids, snoozeTime: timestamp)
    }

    func unsnooze(conversation ids: [Id]) -> UnsnoozeConversationsResult {
        unsnoozeConversations(session: mailUserSession(), ids: ids)
    }
}
