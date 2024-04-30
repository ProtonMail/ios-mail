// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonInboxICal

public struct AnswerInvitationEmailBodyFormatter {
    private let localization: L10nProviding

    public init(localization: L10nProviding) {
        self.localization = localization
    }

    public func string(
        from event: ICalEvent,
        with answer: AttendeeStatusDisplay,
        attendeeEmail: String
    ) -> String {
        let email = attendeeEmail
        let localizedStatus = localizedString(for: answer)
        let eventTitle = event.title ?? localization.localizedString(for: .eventNoTitle)

        return localization.localizedString(for: .emailInvitationBodyContent(
            email: email,
            localizedStatus: localizedStatus,
            eventTitle: eventTitle
        ))
    }

    private func localizedString(for status: AttendeeStatusDisplay) -> String {
        let key: L10nKey

        switch status {
        case .maybe:
            key = .emailInvitationBodyAttendeeStatusDescriptionTentative
        case .yes:
            key = .emailInvitationBodyAttendeeStatusDescriptionAccepted
        case .no:
            key = .emailInvitationBodyAttendeeStatusDescriptionDeclined
        }

        return localization.localizedString(for: key)
    }

}
