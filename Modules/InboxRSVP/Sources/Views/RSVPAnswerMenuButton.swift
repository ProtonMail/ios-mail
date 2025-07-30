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

struct RSVPAnswerMenuButton: View {
    let state: RsvpAnswer
    let isAnswering: Bool
    let action: (RsvpAnswer) -> Void

    var body: some View {
        Menu {
            ForEach(RsvpAnswer.allCases.removing { $0 == state }, id: \.self) { answer in
                RSVPMenuOptionButton(
                    text: answer.humanReadable.long,
                    action: { action(answer) },
                    trailingIcon: .none
                )
            }
        } label: {
            HStack(spacing: DS.Spacing.compact) {
                Text(state.humanReadable.long.string)
                Image(symbol: isAnswering ? .arrowCirclePath : .chevronDown)
            }
        }
        .buttonStyle(RSVPButtonStyle.answerButtonStyle)
    }
}

private extension Array {

    func removing(_ shouldBeExcluded: (Self.Element) throws -> Bool) rethrows -> [Self.Element] {
        try filter { item in try !shouldBeExcluded(item) }
    }

}
