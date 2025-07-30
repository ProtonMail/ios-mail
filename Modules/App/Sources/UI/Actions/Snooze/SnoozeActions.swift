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

import Foundation
import InboxCore
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct SnoozeActions: Hashable {
    let options: [SnoozeTime]
    let showUnsnooze: Bool
}

enum SnoozeTime: Hashable {
    case tomorrow(UnixTimestamp)
    case laterThisWeek(UnixTimestamp)
    case thisWeekend(UnixTimestamp)
    case nextWeek(UnixTimestamp)
    case custom
}

extension SnoozeTime {

    var title: LocalizedStringResource {
        switch self {
        case .tomorrow:
            L10n.Snooze.snoozeTomorrow
        case .laterThisWeek:
            L10n.Snooze.snoozeLaterThisWeek
        case .nextWeek:
            L10n.Snooze.snoozeNextWeek
        case .thisWeekend:
            L10n.Snooze.snoozeThisWeekend
        case .custom:
            L10n.Snooze.customButtonTitle
        }
    }

    var icon: Image {
        switch self {
        case .tomorrow:
            Image(symbol: .sunMax)
        case .laterThisWeek:
            Image(symbol: .sunLeftHalfFilled)
        case .thisWeekend:
            Image(symbol: .sofa)
        case .nextWeek:
            Image(symbol: .suitcase)
        case .custom:
            Image(DS.Icon.icCalendarToday)
        }
    }

    var subtitle: String {
        switch self {
        case .tomorrow(let timestamp):
            SnoozeFormatter.timeOnlyFormatter.string(from: timestamp.date)
        case .laterThisWeek(let timestamp), .thisWeekend(let timestamp), .nextWeek(let timestamp):
            SnoozeFormatter.weekDayWithTimeFormatter.string(from: timestamp.date)
        case .custom:
            L10n.Snooze.customButtonSubtitle.string
        }
    }

}

private enum SnoozeFormatter {
    static let timeOnlyFormatter = {
        let formatter = DateFormatter.fromEnvironmentCalendar()
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter
    }()

    static let weekDayWithTimeFormatter = {
        let formatter = DateFormatter.fromEnvironmentCalendar()
        formatter.setLocalizedDateFormatFromTemplate("EEEEjm")
        return formatter
    }()
}

//

enum AvailableSnoozeActionsForConversationResult {
    case ok(SnoozeActions)
    case error(SnoozeError)
}

enum SnoozeErrorReason {
    case snoozeTimeInThePast
    case invalidSnoozeLocation
}

enum SnoozeError {
    case reason(SnoozeErrorReason)
    case other(ProtonError)
}

enum SnoozeConversationsResult {
    case ok
    case error(SnoozeError)
}

enum UnsnoozeConversationsResult {
    case ok
    case error(SnoozeError)
}

func snoozeConversations(session: MailUserSession, ids: [Id], snoozeTime: UnixTimestamp) -> SnoozeConversationsResult {
    .ok
}

func unsnoozeConversations(session: MailUserSession, ids: [Id]) -> UnsnoozeConversationsResult {
    .ok
}

func availableSnoozeActionsForConversation(session: MailUserSession, weekStart: NonDefaultWeekStart, id: Id) -> AvailableSnoozeActionsForConversationResult {
    .ok(.init(
        options: [.custom, .tomorrow(1753869563), .laterThisWeek(1753869563), .thisWeekend(1753869563)],
        showUnsnooze: true)
    )
}

enum NonDefaultWeekStart : UInt8 {
    case monday = 1
    case saturday = 6
    case sunday = 7
}
