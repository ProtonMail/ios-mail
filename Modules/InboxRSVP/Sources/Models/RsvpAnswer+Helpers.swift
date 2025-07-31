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
import Foundation

extension RsvpAnswer: @retroactive CaseIterable {
    var attendeeStatus: RsvpAttendeeStatus {
        switch self {
        case .yes:
            .yes
        case .maybe:
            .maybe
        case .no:
            .no
        }
    }

    var humanReadable: (short: LocalizedStringResource, long: LocalizedStringResource) {
        switch self {
        case .yes:
            (L10n.Answer.yes, L10n.Answer.yesLong)
        case .maybe:
            (L10n.Answer.maybe, L10n.Answer.maybeLong)
        case .no:
            (L10n.Answer.no, L10n.Answer.noLong)
        }
    }

    // MARK: - CaseIterable

    public static var allCases: [RsvpAnswer] {
        [.yes, .maybe, .no]
    }
}
