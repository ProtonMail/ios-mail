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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

extension View {
    func conversationDetailToolbars(
        model: ConversationDetailModel
    ) -> some View {
        modifier(ConversationDetailToolbars(model: model))
    }
}

private struct ConversationDetailToolbars: ViewModifier {
    @EnvironmentObject var refreshToolbarNotifier: RefreshToolbarNotifier
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @Environment(\.proceedAfterMove) var proceedAfterMove
    @ObservedObject var model: ConversationDetailModel

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .conversationTopToolbar(
                title: topToolbarTitle,
                trailingButton: {
                    navigationTrailingButton
                        .square(size: 40)
                }
            )
            .smoothScreenTransition()
            .conversationBottomToolbar(
                actions: model.conversationToolbarActions,
                mailbox: { model.mailbox.unsafelyUnwrapped },
                messageAppearanceOverrideStore: model.messageAppearanceOverrideStore,
                editToolbarTapped: { toolbarType in model.actionSheets.editToolbar = toolbarType },
                messageActionSelected: { action in
                    if let messageID = model.state.singleMessageIDInMessageMode {
                        Task {
                            await model.handle(
                                action: action,
                                messageID: messageID,
                                toastStateStore: toastStateStore,
                            ) {
                                proceedAfterMove()
                            }
                        }
                    }
                },
                conversationActionSelected: { action in
                    Task {
                        await model.handle(action: action, toastStateStore: toastStateStore) {
                            proceedAfterMove()
                        }
                    }
                }
            )
            .onReceive(refreshToolbarNotifier.refreshToolbar) { toolbarType in
                if toolbarType == .message || toolbarType == .conversation {
                    Task {
                        await model.reloadBottomBarActions()
                    }
                }
            }
            .toolbar(model.isBottomBarHidden ? .hidden : .visible, for: .bottomBar)
            .bottomToolbarStyle()
            .animation(.default, value: model.isBottomBarHidden)
    }

    private var topToolbarTitle: AttributedString {
        guard model.state.messagesCount > 0 else { return .init(.empty) }
        if model.isHeaderVisible {
            return attributedTopTitle
        } else {
            return model.isSingleMessageMode ? .init(.empty) : attributedNumberOfMessages
        }
    }

    private var attributedTopTitle: AttributedString {
        var text = AttributedString(model.seed.subject)
        text.font = .system(.body, weight: .semibold)
        text.foregroundColor = DS.Color.Text.norm
        return text
    }

    private var attributedNumberOfMessages: AttributedString {
        var text = AttributedString(localized: L10n.Conversation.messages(count: model.state.messagesCount))
        text.font = .caption
        text.foregroundColor = DS.Color.Text.hint
        return text
    }

    @ViewBuilder
    private var navigationTrailingButton: some View {
        if !model.areActionsHidden {
            Button(
                action: {
                    model.toggleStarState()
                },
                label: {
                    Image(symbol: model.isStarred ? .starFilled : .star)
                        .foregroundStyle(model.isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
                })
        } else {
            Color.clear
        }
    }
}

/**
 With the combination of a white background toolbar and clipping the content to the scrollview area
 we manage to have a nice UI transition from the mailbox to an expanded message that we have to scroll to.
 */
private struct ModifiersForSmoothScreenTransition: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar, .tabBar)
            .clipped()
            .background(DS.Color.Background.norm)  // has to go before the clipping
    }
}

private extension View {
    func smoothScreenTransition() -> some View {
        modifier(ModifiersForSmoothScreenTransition())
    }
}

private extension ConversationDetailModel.State {
    var messagesCount: Int {
        switch self {
        case .initial, .fetchingMessages, .noConnection:
            0
        case .messagesReady(let messageListState):
            messageListState.messages.count
        }
    }
}
