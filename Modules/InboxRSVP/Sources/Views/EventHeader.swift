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
import SwiftUI

struct EventHeader: View {
    let title: String
    let formattedDate: String
    let answerButtons: Event.AnswerButtonsState
    let calendarButtonAction: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.standard) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)
                Text(formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(DS.Color.Text.norm)
                    .minimumScaleFactor(0.75)
                if case let .visible(attendance, _) = answerButtons, attendance == .optional {
                    Text(L10n.attendanceOptional)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundStyle(DS.Color.Text.weak)
                }
            }
            Spacer(minLength: 0)
            Button(
                action: calendarButtonAction,
                label: {
                    Image(DS.Images.protonCalendar)
                        .square(size: 52)
                })
        }
    }
}
