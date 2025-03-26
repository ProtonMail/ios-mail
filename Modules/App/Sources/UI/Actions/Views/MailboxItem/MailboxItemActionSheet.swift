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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

typealias ReplyActionsHandler = (_ messageId: ID, _ action: ReplyAction) -> Void

struct MailboxItemActionSheet: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    private let input: MailboxItemActionSheetInput
    private let mailbox: Mailbox
    private let actionsProvider: ActionsProvider
    private let starActionPerformerActions: StarActionPerformerActions
    private let readActionPerformerActions: ReadActionPerformerActions
    private let deleteActions: DeleteActions
    private let moveToActions: MoveToActions
    private let replyActions: ReplyActionsHandler
    private let mailUserSession: MailUserSession
    private let navigation: (MailboxItemActionSheetNavigation) -> Void

    init(
        input: MailboxItemActionSheetInput,
        mailbox: Mailbox,
        actionsProvider: ActionsProvider,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        moveToActions: MoveToActions,
        replyActions: @escaping ReplyActionsHandler,
        mailUserSession: MailUserSession,
        navigation: @escaping (MailboxItemActionSheetNavigation) -> Void
    ) {
        self.input = input
        self.mailbox = mailbox
        self.actionsProvider = actionsProvider
        self.starActionPerformerActions = starActionPerformerActions
        self.readActionPerformerActions = readActionPerformerActions
        self.deleteActions = deleteActions
        self.moveToActions = moveToActions
        self.replyActions = replyActions
        self.mailUserSession = mailUserSession
        self.navigation = navigation
    }

    var body: some View {
        StoreView(store: MailboxItemActionSheetStateStore(
            input: input,
            mailbox: mailbox,
            actionsProvider: actionsProvider,
            starActionPerformerActions: starActionPerformerActions,
            readActionPerformerActions: readActionPerformerActions,
            deleteActions: deleteActions,
            moveToActions: moveToActions,
            mailUserSession: mailUserSession,
            toastStateStore: toastStateStore,
            navigation: navigation
        )) { state, store in
            ClosableScreen {
                ScrollView {
                    VStack(spacing: DS.Spacing.standard) {
                        if let replyActions = state.availableActions.replyActions {
                            replyButtonsSection(replyActions)
                        }

                        mailboxItemActionsSection(state: state, store: store)
                        moveToActionsSection(state: state, store: store)
                        section(state: state, store: store)
                    }.padding(.all, DS.Spacing.large)
                }
                .background(DS.Color.BackgroundInverted.norm)
                .navigationTitle(state.title)
                .navigationBarTitleDisplayMode(.inline)
                .alert(model: store.binding(\.alert))
            }.onLoad { store.handle(action: .onLoad) }
        }
    }

    // MARK: - Private

    private func replyButtonsSection(_ actions: [ReplyAction]) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            ForEach(actions, id: \.self) { action in
                replyButton(action: action)
            }
        }
    }

    private func mailboxItemActionsSection(
        state: MailboxItemActionSheetState,
        store: MailboxItemActionSheetStateStore
    ) -> some View {
        ActionSheetSection {
            ForEachLast(collection: state.availableActions.mailboxItemActions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { store.handle(action: .mailboxItemActionSelected(action)) }
                )
            }
        }
    }

    private func moveToActionsSection(
        state: MailboxItemActionSheetState,
        store: MailboxItemActionSheetStateStore
    ) -> some View {
        ActionSheetSection {
            ForEachLast(collection: state.availableActions.moveActions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { store.handle(action: .moveTo(action)) }
                )
            }
        }
    }

    private func section(
        state: MailboxItemActionSheetState,
        store: MailboxItemActionSheetStateStore
    ) -> some View {
        ActionSheetSection {
            ForEachLast(collection: state.availableActions.generalActions) { action, isLast in
                ActionSheetImageButton(
                    displayData: action.displayData,
                    displayBottomSeparator: !isLast,
                    action: { store.handle(action: .mailboxGeneralActionTapped(action)) }
                )
            }
        }
    }

    private func replyButton(action: ReplyAction) -> some View {
        guard let messageId = input.ids.first else {
            let message = "messageId not found for reply action"
            AppLogger.log(message: message, category: .composer)
            fatalError(message)
        }
        return Button(action: { replyActions(messageId, action) }) {
            VStack(spacing: DS.Spacing.standard) {
                Image(action.displayData.image)
                    .resizable()
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
                Text(action.displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
            }
            .frame(height: 84)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(RegularButtonStyle())
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }
}

#Preview {
    MailboxItemActionSheet(
        input: .init(ids: [], type: .message, title: "Hello there".notLocalized),
        mailbox: .dummy,
        actionsProvider: MailboxItemActionSheetPreviewProvider.actionsProvider(),
        starActionPerformerActions: .dummy,
        readActionPerformerActions: .dummy,
        deleteActions: .dummy,
        moveToActions: .dummy,
        replyActions: { _, _ in },
        mailUserSession: .dummy,
        navigation: { _ in }
    )
}

extension Mailbox {

    static var dummy: Mailbox {
        .init(noPointer: .init())
    }

}

extension MailUserSession {

    static var dummy: MailUserSession {
        .init(noPointer: .init())
    }

}
