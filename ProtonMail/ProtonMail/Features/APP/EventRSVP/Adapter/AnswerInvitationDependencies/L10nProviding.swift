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

import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct L10nProvider: L10nProviding {
        func localizedString(for key: L10nKey) -> String {
            switch key {
            case let .emailInvitationSubjectFullDateWithTimeAndTimeZone(
                formattedDate,
                formattedTime,
                formattedTimeZone
            ):
                return String(
                    format: L10n.InvitationEmail.emailInvitationSubjectFullDateWithTimeAndTimeZone,
                    formattedDate,
                    formattedTime,
                    formattedTimeZone
                )
            case .emailInvitationBodyAttendeeStatusDescriptionAccepted:
                return L10n.InvitationEmail.accepted
            case .emailInvitationBodyAttendeeStatusDescriptionDeclined:
                return L10n.InvitationEmail.declined
            case .emailInvitationBodyAttendeeStatusDescriptionTentative:
                return L10n.InvitationEmail.tentativelyAccepted
            case let .emailInvitationBodyContent(email, localizedStatus, eventTitle):
                return String(format: L10n.InvitationEmail.Body.content, email, localizedStatus, eventTitle)
            case .emailInvitationBodyTitle(let eventTitle):
                return String(format: L10n.InvitationEmail.Body.title, eventTitle)
            case .emailInvitationBodyLocation(let locationName):
                return String(format: L10n.InvitationEmail.Body.location, locationName)
            case .emailInvitationBodyNotes(let eventNotes):
                return String(format: L10n.InvitationEmail.Body.notes, eventNotes)
            case .emailCancellationBody(let eventTitle):
                return String(format: L10n.InvitationEmail.cancellationBody, eventTitle)
            case .emailAnswerSubjectAllDaySingle(let formattedDate):
                return String(format: L10n.InvitationEmail.Answer.Subject.allDaySingle, formattedDate)
            case .emailAnswerSubjectOther(let formattedDate):
                return String(format: L10n.InvitationEmail.Answer.Subject.other, formattedDate)
            case .eventNoTitle:
                return L10n.Event.noTitle
            }
        }
    }
}
