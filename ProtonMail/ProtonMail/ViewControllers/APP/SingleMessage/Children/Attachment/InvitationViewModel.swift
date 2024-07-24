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

import ProtonCoreUIFoundations
import UIKit

struct InvitationViewModel {
    let title: String
    let durationString: String
    let isOptionalAttendanceLabelHidden: Bool
    let statusString: String?

    var isStatusViewHidden: Bool {
        statusString == nil
    }

    var titleColor: UIColor {
        isStatusViewHidden ? ColorProvider.TextNorm : ColorProvider.TextWeak
    }

    let organizer: EventDetails.Participant?

    var visibleInvitees: [EventDetails.Participant] {
        switch participantListState {
        case .collapsed:
            return []
        case .expanded, .allInviteesCanBeShownWithoutCollapsing:
            return allInvitees
        }
    }

    var expansionButtonTitle: String? {
        switch participantListState {
        case .collapsed:
            return String(format: L10n.Event.participantCount, allInvitees.count)
        case .expanded:
            return L10n.Event.showLess
        case .allInviteesCanBeShownWithoutCollapsing:
            return nil
        }
    }

    private let allInvitees: [EventDetails.Participant]
    private var participantListState: ParticipantListState

    init(eventDetails: EventDetails) {
        if let title = eventDetails.title, !title.isEmpty {
            self.title = title
        } else {
            title = L10n.Event.noTitle
        }

        durationString = EventDateIntervalFormatter().string(
            from: eventDetails.startDate,
            to: eventDetails.endDate,
            isAllDay: eventDetails.isAllDay
        )

        isOptionalAttendanceLabelHidden = eventDetails.currentUserAmongInvitees?.role != .optional

        if eventDetails.status == .cancelled {
            statusString = L10n.Event.eventCancelled
        } else if eventDetails.endDate.timeIntervalSinceNow < 0 && eventDetails.recurrence == nil {
            statusString = L10n.Event.eventAlreadyEnded
        } else {
            statusString = nil
        }

        organizer = eventDetails.organizer
        allInvitees = eventDetails.invitees

        if eventDetails.invitees.count <= 1 {
            participantListState = .allInviteesCanBeShownWithoutCollapsing
        } else {
            participantListState = .collapsed
        }
    }

    mutating func toggleParticipantListExpansion() {
        switch participantListState {
        case .collapsed:
            participantListState = .expanded
        case .expanded:
            participantListState = .collapsed
        case .allInviteesCanBeShownWithoutCollapsing:
            assertionFailure("It shouldn't be possible to call this")
        }
    }
}

private enum ParticipantListState {
    case collapsed
    case expanded
    case allInviteesCanBeShownWithoutCollapsing
}
