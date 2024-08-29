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
import proton_app_uniffi
import SwiftUI

struct MessageBodyView: View {
    @State var bodyContentHeight: CGFloat = 0.0

    let messageBody: String?
    let messageId: ID
    let uiModel: ExpandedMessageCellUIModel
    let mailbox: Mailbox

    var body: some View {
        if let messageBody = uiModel.message {
            messageBodyView(body: messageBody)
        } else {
            AsyncMessageBodyView(messageId: messageId, mailbox: mailbox) { messageBody in
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
        MessageBodyReaderView(bodyContentHeight: $bodyContentHeight, html: body)
            .frame(height: bodyContentHeight)
            .padding(.vertical, DS.Spacing.large)
            .padding(.horizontal, DS.Spacing.large)
            .accessibilityIdentifier(MessageBodyViewIdentifiers.messageBody)
    }
}

private struct MessageBodyViewIdentifiers {
    static let messageBody = "detail.messageBody"
}
