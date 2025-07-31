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

import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct EventParticipantsView: View {
    let participants: [Event.Participant]
    @State var areParticipantsExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            if participants.count >= 2 {
                EventParticipantsRowButton(count: participants.count, isExpanded: $areParticipantsExpanded) {
                    withAnimation(.easeInOut) {
                        areParticipantsExpanded.toggle()
                    }
                }
                .zIndex(1)
            }
            if areParticipantsExpanded || participants.count == 1 {
                LazyVStack(alignment: .leading, spacing: .zero) {
                    ForEach(participants, id: \.displayName) { participant in
                        EventDetailsRow(
                            icon: participant.status.details.icon,
                            iconColor: participant.status.details.color,
                            text: participant.displayName
                        )
                        .zIndex(-1)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private extension RsvpAttendeeStatus {
    var details: (icon: ImageResource, color: Color) {
        switch self {
        case .unanswered:
            (DS.Icon.icCircleRadioEmpty, DS.Color.Shade.shade40)
        case .maybe:
            (DS.Icon.icQuestionCircle, DS.Color.Notification.warning)
        case .no:
            (DS.Icon.icCrossCircle, DS.Color.Notification.error)
        case .yes:
            (DS.Icon.icCheckmarkCircle, DS.Color.Notification.success)
        }
    }
}
