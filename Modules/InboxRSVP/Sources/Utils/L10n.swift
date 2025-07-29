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

/// Once you define `LocalizedStringResource` below Xcode puts related string in `Localizable.xcstrings` file.
/// The generation happens automatically when adding/removing string below. All keys are added in alphabetical order.
/// IMPORTANT: Remember about setting bundle for each key: `bundle: .module`.
enum L10n {
    static let noEventTitlePlacholder = LocalizedStringResource(
        "(no title)",
        bundle: .module,
        comment: "Placeholder text for an event that has no title or summary."
    )
    static let attendanceOptional = LocalizedStringResource(
        "(Attendance optional)",
        bundle: .module,
        comment: "A note indicating that responding to or attending the event is not mandatory."
    )

    enum Answer {
        static let attending = LocalizedStringResource(
            "Attending?",
            bundle: .module,
            comment: "A question prompting the user to select their attendance status."
        )
        static let yes = LocalizedStringResource(
            "Yes",
            bundle: .module,
            comment: "A short, one-word response indicating the user will attend the event."
        )
        static let maybe = LocalizedStringResource(
            "Maybe",
            bundle: .module,
            comment: "A short, one-word response indicating the user might attend the event."
        )
        static let no = LocalizedStringResource(
            "No",
            bundle: .module,
            comment: "A short, one-word response indicating the user will not attend the event."
        )
        static let yesLong = LocalizedStringResource(
            "Yes, I'll attend",
            bundle: .module,
            comment: "A full-sentence response indicating the user will attend. Used in menus."
        )
        static let maybeLong = LocalizedStringResource(
            "Maybe, I'll attend",
            bundle: .module,
            comment: "A full-sentence response indicating the user might attend. Used in menus."
        )
        static let noLong = LocalizedStringResource(
            "No, I won't attend",
            bundle: .module,
            comment: "A full-sentence response indicating the user will not attend. Used in menus."
        )
    }

    enum Header {
        static let happening = LocalizedStringResource(
            "Happening",
            bundle: .module,
            comment: "First part of the 'Happening now' banner, indicating an event is currently in progress."
        )
        static let now = LocalizedStringResource(
            " now",
            bundle: .module,
            comment: "Second part of the 'Happening now' banner, meant to be bolded. Note the leading space."
        )
        static let event = LocalizedStringResource(
            "Event",
            bundle: .module,
            comment: "The subject of a status update, like 'Event ended' or 'Event canceled'."
        )
        static let ended = LocalizedStringResource(
            " ended",
            bundle: .module,
            comment: "The status of an event that has finished. Meant to be bolded. Note the leading space."
        )
        static let canceled = LocalizedStringResource(
            " canceled",
            bundle: .module,
            comment: "The status of an event that has been canceled. Meant to be bolded. Note the leading space."
        )
        static let inviteIsOutdated = LocalizedStringResource(
            "This invitation is out of date. The event has been updated.",
            bundle: .module,
            comment: "Banner text explaining that the event details have changed since the invitation was sent."
        )
        static let offlineWarning = LocalizedStringResource(
            "You're offline. The displayed information may be out-of-date.",
            bundle: .module,
            comment: "Warning banner shown when the user has no internet connection."
        )
        static let cancelledAndOutdated = LocalizedStringResource(
            "Event cancelled. This invitation is out of date.",
            bundle: .module,
            comment: "Banner for a cancelled event where the user is also viewing an outdated invitation."
        )
    }

    enum Details {
        static func participantsCount(count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(count) Participants",
                bundle: .module,
                comment: "Label for the participants button, where %d is the number of people. Exist only in plural form."
            )
        }
        static func organizer(name: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(name) (Organizer)",
                bundle: .module,
                comment: "Label showing the organizer's name with a clarifying '(Organizer)' suffix."
            )
        }
        static func you(email: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "You • \(email)",
                bundle: .module,
                comment: "A label to identify the current user in a list of event attendees."
            )
        }
    }

    enum Error {
        static let title = LocalizedStringResource(
            "Invite details unavailable",
            bundle: .module,
            comment: "Title shown when calendar event loading fails, providing additional context to the user."
        )

        static let subtitle = LocalizedStringResource(
            "We couldn’t load the\ninformation. Please try again.",
            bundle: .module,
            comment: "Subtitle shown when calendar event loading fails, providing additional context to the user."
        )

        static let retryButtonTitle = LocalizedStringResource(
            "Retry",
            bundle: .module,
            comment: "Title of the button that allows the user to retry loading the event after an error."
        )
    }

    enum OrganizerMenuOption {
        static let copyAction = LocalizedStringResource(
            "Copy address",
            bundle: .module,
            comment: "Context menu option to copy the organizer’s email address to the clipboard."
        )
        static let newMessage = LocalizedStringResource(
            "Message",
            bundle: .module,
            comment: "Context menu option to start composing a new message to the organizer."
        )
    }
}
