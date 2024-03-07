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

struct MailboxConversationScreen: View {
    @State var model: MailboxConversationScreenModel

    var body: some View {
        List {
            ForEach(model.conversations) { conversation in
                MailboxConversationCell(
                    uiModel: conversation,
                    onEvent: { [weak model] event in
                        switch event {
                        case .onSelectedChange(let isSelected):
                            model?.onConversationSelectionChange(id: conversation.id, isSelected: isSelected)
                        case .onStarredChange(let isStarred):
                            model?.onConversationStarChange(id: conversation.id, isStarred: isStarred)
                        case .onAttachmentTap(let attachmentId):
                            model?.onAttachmentTap(attachmentId: attachmentId)
                        }
                    }
                )
                .listRowInsets(
                    .init(top: 1, leading: 1, bottom: 1, trailing: 0)
                )
                .listRowSeparator(.hidden)
                .compositingGroup()
                .clipShape(
                    .rect(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    return MailboxConversationScreen(model: PreviewData.mailboxConversationScreenModel)
}
