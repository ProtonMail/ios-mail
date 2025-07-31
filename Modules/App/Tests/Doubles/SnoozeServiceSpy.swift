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

@testable import ProtonMail
import proton_app_uniffi

class SnoozeServiceSpy: SnoozeServiceProtocol {
    lazy var snoozeActionsStub: SnoozeActions = .init(
        options: [.custom, .tomorrow(.timestamp), .nextWeek(.timestamp), .thisWeekend(.timestamp)],
        showUnsnooze: true
    )

    private(set) var invokedAvailableSnoozeActions: [(weekStart: NonDefaultWeekStart, id: ID)] = []
    private(set) var invokedSnooze: [(ids: [ID], timestamp: UnixTimestamp)] = []
    private(set) var invokedUnsnooze: [[ID]] = []

    // MARK: - SnoozeServiceProtocol

    func availableSnoozeActions(
        for conversation: Id,
        systemCalendarWeekStart: NonDefaultWeekStart
    ) -> AvailableSnoozeActionsForConversationResult {
        invokedAvailableSnoozeActions.append((systemCalendarWeekStart, conversation))

        return .ok(snoozeActionsStub)
    }

    func snooze(conversation ids: [Id], timestamp: UnixTimestamp) -> SnoozeConversationsResult {
        invokedSnooze.append((ids, timestamp))

        return .ok(nil)
    }

    func unsnooze(conversation ids: [Id]) -> UnsnoozeConversationsResult {
        invokedUnsnooze.append(ids)

        return .ok(nil)
    }
}
