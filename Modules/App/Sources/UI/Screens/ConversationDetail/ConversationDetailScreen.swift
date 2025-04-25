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

import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct ConversationDetailScreen: View {
    @StateObject private var model: ConversationDetailModel
    @State private var animateViewIn: Bool = false
    @State private var isHeaderVisible: Bool = false
    @EnvironmentObject var toastStateStore: ToastStateStore
    @Binding private var navigationPath: NavigationPath
    private let draftPresenter: DraftPresenter

    init(seed: ConversationDetailSeed, draftPresenter: DraftPresenter, navigationPath: Binding<NavigationPath>) {
        self._model = StateObject(wrappedValue: .init(seed: seed, draftPresenter: draftPresenter))
        self._navigationPath = .init(projectedValue: navigationPath)
        self.draftPresenter = draftPresenter
    }

    var body: some View {
        ZStack {
            conversationView
            if !model.areActionsDisabled {
                BottomActionBarView(
                    actions: model.bottomBarActions,
                    tapAction: { action in
                        model.handleConversation(
                            action: action,
                            toastStateStore: toastStateStore,
                            goBack: { navigationPath.removeLast() }
                        )
                    }
                )
            }
        }
        .actionSheetsFlow(
            mailbox: { model.mailbox.unsafelyUnwrapped },
            state: $model.actionSheets,
            replyActions: handleReplyAction,
            goBackNavigation: { navigationPath.removeLast() }
        )
        .alert(model: $model.deleteConfirmationAlert)
        .fullScreenCover(item: $model.attachmentIDToOpen) { id in
            AttachmentView(config: .init(id: id, mailbox: model.mailbox.unsafelyUnwrapped))
                .edgesIgnoringSafeArea([.top, .bottom])
        }
        .environment(\.messageAppearanceOverrideStore, model.messageAppearanceOverrideStore)
    }

    private var conversationView: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    ListHeaderView(isHeaderVisible: $isHeaderVisible, parentGeometry: proxy) {
                        subjectView
                            .padding(.top, DS.Spacing.medium)
                            .padding(.horizontal, DS.Spacing.large)
                    }
                    ConversationDetailListView(model: model)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ConversationDetailScreenIdentifiers.rootItem)
            }
            .navigationBarTitleDisplayMode(.inline)
            .conversationTopToolbar(title: topToolbarTitle, trailingButton: {
                navigationTrailingButton
                    .square(size: 40)
            })
            .opacity(animateViewIn ? 1.0 : 0.0)
            .smoothScreenTransition()
            .ignoresSafeArea(.all, edges: .bottom)
            .padding(.bottom, model.areActionsDisabled ? 0 : proxy.safeAreaInsets.bottom + 45)
            .task {
                withAnimation(.easeIn) {
                    animateViewIn = true
                }
                await model.fetchInitialData()
            }
        }
    }

    private var topToolbarTitle: AttributedString {
        guard model.state.messagesCount > 0 else { return .init(.empty) }
        return isHeaderVisible ? attributedTopTitle : attributedNumberOfMessages
    }

    private var attributedTopTitle: AttributedString {
        var text = AttributedString(model.seed.subject)
        text.font = .system(.body, weight: .semibold)
        text.foregroundColor = DS.Color.Text.norm
        return text
    }

    private var attributedNumberOfMessages: AttributedString {
        var text = AttributedString(localized: L10n.messages(count: model.state.messagesCount))
        text.font = .caption
        text.foregroundColor = DS.Color.Text.weak
        return text
    }

    private var subjectView: some View {
        Text(model.seed.subject)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityIdentifier(ConversationDetailScreenIdentifiers.subjectText)
    }

    @ViewBuilder
    private var navigationTrailingButton: some View {
        if !model.areActionsDisabled {
            Button(action: {
                model.toggleStarState()
            }, label: {
                Image(model.isStarred ? DS.Icon.icStarFilled : DS.Icon.icStar)
                    .foregroundStyle(model.isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
            })
        } else {
            Color.clear
        }
    }

    private func handleReplyAction(messageId: ID, action: ReplyAction) {
        Task {
            await draftPresenter.handleReplyAction(for: messageId, action: action) { error in
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }
}

private struct ModifiersForSmoothScreenTransition: ViewModifier {

    func body(content: Content) -> some View {
        /**
         With the combination of a white background toolbar and clipping the content to the scrollview area
         we manage to have a nice UI transition from the mailbox to an expanded message that we have to scroll to.
         */
        content
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar, .tabBar)
            .clipped()
            .background(DS.Color.Background.norm)  // has to go before the clipping
    }
}

private extension View {

    func smoothScreenTransition() -> some View {
        self.modifier(ModifiersForSmoothScreenTransition())
    }
}

private extension ConversationDetailModel.State {

    var messagesCount: Int {
        switch self {
        case .initial, .fetchingMessages, .noConnection:
            0
        case .messagesReady(let previous, let last):
            (previous + [last]).count
        }
    }

}

#Preview("From Mailbox") {
    NavigationView {
        ConversationDetailScreen(
            seed: .mailboxItem(
                item: .init(
                    id: .random(),
                    conversationID: .random(),
                    type: .conversation,
                    avatar: .init(info: .init(initials: "Pf", color: .blue), type: .sender(params: .init())),
                    emails: "",
                    subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia",
                    date: .now,
                    locationIcon: nil,
                    isRead: true,
                    isStarred: true,
                    isSelected: false,
                    isSenderProtonOfficial: true,
                    messagesCount: 3,
                    labelUIModel: MailboxLabelUIModel(
                        labelModels: [LabelUIModel(labelId: .init(value: 0), text: "Work", color: .blue)]
                    ),
                    attachmentsUIModel: [
                        .init(id: .init(value: 4), icon: DS.Icon.icFileTypeIconWord, name: "notes.doc")
                    ],
                    expirationDate: nil,
                    snoozeDate: nil,
                    isDraftMessage: false
                ),
                selectedMailbox: .inbox
            ),
            draftPresenter: .dummy,
            navigationPath: .constant(.init())
        )
    }
}

#Preview("From Notification") {
    NavigationView {
        ConversationDetailScreen(
            seed: .pushNotification(.init(
                remoteId: .init(value: ""),
                subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia"
            )),
            draftPresenter: .dummy,
            navigationPath: .constant(.init())
        )
    }
}

private struct ConversationDetailScreenIdentifiers {
    static let rootItem = "detail.rootItem"
    static let subjectText = "detail.subjectText"
}

extension ConversationDetailSeed {

    var isOutbox: Bool {
        switch self {
        case .mailboxItem(_, let selectedMailbox):
            selectedMailbox.systemFolder == .outbox
        case .pushNotification:
            false
        }
    }

}
