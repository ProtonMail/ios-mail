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

import DesignSystem
import SwiftUI

struct MessageBodyView: View {
    let messageBody: String?
    let messageId: PMLocalMessageId
    let uiModel: ExpandedMessageCellUIModel

    var body: some View {
        if let messageBody = uiModel.message {
            messageBodyView(body: messageBody)

        } else {
            AsyncMessageBodyView(messageId: messageId) { messageBody in
                switch messageBody {
                case .fetching:
                    ZStack {
                        ProgressView()
                    }
                    .padding(.vertical, DS.Spacing.jumbo)

                case .value(let body):
                    messageBodyView(body: body)

                case .error(let error):
                    Text(String(describing: error))

                }
            }
        }
    }

    private func messageBodyView(body: String) -> some View {
        /**
         Using `Text` for large body messages could choke the main thread and also arndomly
         cap the amount of rendered characters.
         TextEditor performs really well, but selection by double tap scrolls to the bottom ??!!
         To be reviewed when working on rendering the message body.
         */
        TextEditor(text: .constant(body))
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
            .font(.subheadline)
            .foregroundStyle(DS.Color.Text.norm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DS.Spacing.large)
            .padding(.horizontal, DS.Spacing.large)

    }
}
