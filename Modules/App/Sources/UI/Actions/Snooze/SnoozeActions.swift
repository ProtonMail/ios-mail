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

// MARK: - Rust API - to remove

import InboxCore
import InboxDesignSystem
import Foundation

struct SnoozeActions {
    let predefined: [PredefinedSnooze]
    let isUnsnoozeVisible: Bool
    let customButtonType: CustomButtonType

    enum CustomButtonType {
        case regular
        case upgrade
    }
}

struct PredefinedSnooze: Hashable {
    let type: PredefinedSnoozeType
    let date: Date

    enum PredefinedSnoozeType: Hashable {
        case tomorrow
        case laterThisWeek
        case thisWeekend
        case nextWeek
    }
}

extension PredefinedSnooze {

    var title: LocalizedStringResource {
        switch type {
        case .tomorrow:
            L10n.Snooze.snoozeTomorrow
        case .laterThisWeek:
            L10n.Snooze.snoozeLaterThisWeek
        case .nextWeek:
            L10n.Snooze.snoozeNextWeek
        case .thisWeekend:
            L10n.Snooze.snoozeThisWeekend
        }
    }

    var icon: DS.SFSymbol {
        switch type {
        case .tomorrow:
            .sunMax
        case .laterThisWeek:
            .sunLeftHalfFilled
        case .thisWeekend:
            .sofa
        case .nextWeek:
            .suitcase
        }
    }

    var time: String {
        let formatter =
            switch type {
            case .tomorrow:
                SnoozeFormatter.timeOnlyFormatter
            case .laterThisWeek, .thisWeekend, .nextWeek:
                SnoozeFormatter.weekDayWithTimeFormatter
            }
        return formatter.string(from: date)
    }

}

private enum SnoozeFormatter {
    static let timeOnlyFormatter = {
        let formatter = DateFormatter()
        formatter.locale = DateEnvironment.calendar.locale
        formatter.timeZone = DateEnvironment.calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jm")
        return formatter
    }()

    static let weekDayWithTimeFormatter = {
        let formatter = DateFormatter()
        formatter.locale = DateEnvironment.calendar.locale
        formatter.timeZone = DateEnvironment.calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEEjm")
        return formatter
    }()
}
