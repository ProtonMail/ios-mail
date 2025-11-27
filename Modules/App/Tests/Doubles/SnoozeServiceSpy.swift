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

@testable import ProtonMail

class SnoozeServiceSpy: SnoozeServiceProtocol {
    var snoozeOptionsStub: [SnoozeTime] {
        [.custom, .tomorrow(.timestamp), .nextWeek(.timestamp), .thisWeekend(.timestamp)]
    }

    lazy var snoozeActionsStub: AvailableSnoozeActionsForConversationResult = .ok(
        .init(
            options: snoozeOptionsStub,
            showUnsnooze: true
        )
    )

    var snoozeResultStub: SnoozeConversationsResult = .ok
    var unsnoozeResultStub: UnsnoozeConversationsResult = .ok

    private(set) var invokedAvailableSnoozeActions: [(weekStart: NonDefaultWeekStart, id: [ID])] = []
    private(set) var invokedSnooze: [(ids: [ID], labelId: Id, timestamp: UnixTimestamp)] = []
    private(set) var invokedUnsnooze: [(ids: [ID], labelId: Id)] = []

    // MARK: - SnoozeServiceProtocol

    func availableSnoozeActions(
        for conversation: [Id],
        systemCalendarWeekStart: NonDefaultWeekStart
    ) async -> AvailableSnoozeActionsForConversationResult {
        invokedAvailableSnoozeActions.append((systemCalendarWeekStart, conversation))

        return snoozeActionsStub
    }

    func snooze(
        conversation ids: [Id],
        labelId: Id,
        timestamp: UnixTimestamp
    ) async -> SnoozeConversationsResult {
        invokedSnooze.append((ids, labelId, timestamp))

        return snoozeResultStub
    }

    func unsnooze(conversation ids: [Id], labelId: Id) async -> UnsnoozeConversationsResult {
        invokedUnsnooze.append((ids, labelId))

        return unsnoozeResultStub
    }
}
