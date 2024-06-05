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

public protocol L10nProviding {
    func localizedString(for key: L10nKey) -> String
}

public enum L10nKey {
    case emailInvitationSubjectFullDateWithTimeAndTimeZone(
        formattedDate: String,
        formattedTime: String,
        formattedTimeZone: String
    )
    case emailInvitationBodyAttendeeStatusDescriptionAccepted
    case emailInvitationBodyAttendeeStatusDescriptionDeclined
    case emailInvitationBodyAttendeeStatusDescriptionTentative
    case emailInvitationBodyContent(email: String, localizedStatus: String, eventTitle: String)
    case emailInvitationBodyTitle(eventTitle: String)
    case emailInvitationBodyLocation(locationName: String)
    case emailInvitationBodyNotes(eventNotes: String)
    case emailCancellationBody(eventTitle: String)
    case emailAnswerSubjectAllDaySingle(formattedDate: String)
    case emailAnswerSubjectOther(formattedDate: String)
    case eventNoTitle
}
