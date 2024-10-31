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

import Combine
import InboxCore
import proton_app_uniffi

class MailboxItemActionSheetModel: ObservableObject {
    @Published var state: MailboxItemActionSheetState
    private let availableActionsProvider: AvailableActionsProvider
    private let input: MailboxItemActionSheetInput
    private let starActionPerformer: StarActionPerformer
    private let readActionPerformer: ReadActionPerformer
    private let navigation: (MailboxItemActionSheetNavigation) -> Void

    init(
        input: MailboxItemActionSheetInput,
        mailbox: Mailbox,
        actionsProvider: ActionsProvider,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        mailUserSession: MailUserSession,
        navigation: @escaping (MailboxItemActionSheetNavigation) -> Void
    ) {
        self.input = input
        self.availableActionsProvider = .init(actionsProvider: actionsProvider, mailbox: mailbox)
        self.starActionPerformer = .init(
            mailUserSession: mailUserSession,
            starActionPerformerActions: starActionPerformerActions
        )
        self.readActionPerformer = .init(mailbox: mailbox, readActionPerformerActions: readActionPerformerActions)
        self.state = .initial(title: input.title)
        self.navigation = navigation
    }

    func handle(action: MailboxItemActionSheetAction) {
        switch action {
        case .viewAppear:
            loadActions()
        case .mailboxItemActionSelected(let action):
            switch action {
            case .labelAs:
                navigation(.labelAs)
            case .star:
                performAction(action: starActionPerformer.star, ids: input.ids, itemType: input.type)
            case .unstar:
                performAction(action: starActionPerformer.unstar, ids: input.ids, itemType: input.type)
            case .markRead:
                performAction(action: readActionPerformer.markAsRead, ids: input.ids, itemType: input.type)
            case .markUnread:
                performAction(action: readActionPerformer.markAsUnread, ids: input.ids, itemType: input.type)
            default:
                break // FIXME: - Handle rest of actions here
            }
        case .moveTo(let action):
            switch action {
            case .moveTo:
                navigation(.moveTo)
            default:
                break // FIXME: - Handle rest of actions here
            }
        }
    }

    // MARK: - Private

    private func performAction(
        action: ([ID], MailboxItemType, (() -> Void)?) -> Void,
        ids: [ID],
        itemType: MailboxItemType
    ) {
        action(ids, itemType) { [weak self] in
            self?.dismiss()
        }
    }

    private func dismiss() {
        Dispatcher.dispatchOnMain(.init(block: { [weak self] in
            self?.navigation(.dismiss)
        }))
    }

    private func loadActions() {
        Task {
            let actions = await availableActionsProvider.actions(for: input.type, ids: input.ids)
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.update(actions: actions)
            }))
        }
    }

    private func update(actions: AvailableActions) {
        state = state.copy(availableActions: actions)
    }
}

private extension MailboxItemActionSheetState {
    static func initial(title: String) -> Self {
        .init(
            title: title,
            availableActions: .init(
                replyActions: [],
                mailboxItemActions: [],
                moveActions: [],
                generalActions: []
            )
        )
    }

    func copy(availableActions: AvailableActions) -> Self {
        .init(title: title, availableActions: availableActions)
    }
}
