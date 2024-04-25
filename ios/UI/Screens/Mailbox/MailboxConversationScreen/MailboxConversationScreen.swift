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
    @EnvironmentObject var userSettings: UserSettings
    @ObservedObject private var model: MailboxConversationModel

    init(model: MailboxConversationModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            switch model.state {
            case .loading:
                loadingView
            case .empty:
                MailboxEmptyView()
            case .data(let conversations):
                conversationListView(conversations: conversations)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension MailboxConversationScreen {

    private var loadingView: some View {
        ProgressView()
    }

    private func conversationListView(conversations: [MailboxConversationCellUIModel]) -> some View {
        List {
            ForEach(conversations) { conversation in
                VStack {
                    MailboxConversationCell(
                        uiModel: conversation,
                        onEvent: { [weak model] event in
                            switch event {
                            case .onTap:
                                model?.onConversationTap(conversation: conversation)
                            case .onSelectedChange(let isSelected):
                                model?.onConversationSelectionChange(conversation: conversation, isSelected: isSelected)
                            case .onStarredChange(let isStarred):
                                model?.onConversationStarChange(id: conversation.id, isStarred: isStarred)
                            case .onAttachmentTap(let attachmentId):
                                model?.onConversationAttachmentTap(attachmentId: attachmentId)
                            }
                        }
                    )
                    .mailboxSwipeActions(
                        isSelectionModeOn: model.selectionMode.hasSelectedItems,
                        itemId: conversation.id,
                        isItemRead: conversation.isRead,
                        onTapAction: model.onConversationAction(_:conversationIds:)
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
                .background(DS.Color.Background.norm) // cell background color after clipping
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    let route: AppRouteState = .init(route: .mailbox(label: .placeHolderMailbox))
    let selectionMode = SelectionModeState()

    struct PreviewWrapper: View {
        @State var appRoute: AppRouteState
        @State var selectionMode: SelectionModeState

        var body: some View {
            MailboxConversationScreen(model: .init(
                appRoute: appRoute,
                selectionMode: selectionMode,
                state: .empty // .data(PreviewData.mailboxConversations)
            ))
        }
    }
    return PreviewWrapper(appRoute: route, selectionMode: selectionMode)
}
