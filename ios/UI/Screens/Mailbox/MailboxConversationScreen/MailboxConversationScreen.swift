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
    private var model: MailboxConversationType

    init(model: MailboxConversationType) {
        self.model = model
    }

    var body: some View {
        ZStack {
            switch model.output.state {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .empty:
                VStack {
                    Text("No conversations")
                }
            case .data(let conversations):
                List {
                    ForEach(conversations) { conversation in
                        VStack {
                            MailboxConversationCell(
                                uiModel: conversation,
                                onEvent: { [weak model] event in
                                    switch event {
                                    case .onSelectedChange(let isSelected):
                                        model?.input.onConversationSelectionChange(id: conversation.id, isSelected: isSelected)
                                    case .onStarredChange(let isStarred):
                                        model?.input.onConversationStarChange(id: conversation.id, isStarred: isStarred)
                                    case .onAttachmentTap(let attachmentId):
                                        model?.input.onAttachmentTap(attachmentId: attachmentId)
                                    }
                                }
                            )
                            Spacer().frame(height: DS.Spacing.tiny)
                        }
                        .listRowInsets(
                            .init(top: 0, leading: DS.Spacing.tiny, bottom: 0, trailing: 0)
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
    }
}

#Preview {
    let mailboxConversationModel = MailboxConversationModel(
        selectedMailbox: .defaultMailbox,
        state: .data(PreviewData.mailboxConversations)
    )
    return MailboxConversationScreen(model: mailboxConversationModel)
}
