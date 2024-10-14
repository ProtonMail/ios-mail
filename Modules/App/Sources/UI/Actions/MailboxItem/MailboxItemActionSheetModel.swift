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
import proton_app_uniffi

class MailboxItemActionSheetModel: ObservableObject {
    @Published var state: MailboxItemActionSheetState
    private let availableActionsProvider: AvailableActionsProvider
    private let input: MailboxItemActionSheetInput
    private let navigation: (MailboxItemActionSheetNavigation) -> Void

    init(
        input: MailboxItemActionSheetInput,
        mailbox: Mailbox,
        actionsProvider: ActionsProvider,
        navigation: @escaping (MailboxItemActionSheetNavigation) -> Void
    ) {
        self.input = input
        self.availableActionsProvider = .init(actionsProvider: actionsProvider, mailbox: mailbox)
        self.state = .initial(title: input.title)
        self.navigation = navigation
    }

    func handle(action: MailboxItemActionSheetAction) {
        switch action {
        case .viewAppear:
            loadActions()
        case .mailbox(let action):
            switch action {
            case .labelAs:
                navigation(.labelAs)
            default:
                break
            }
        }
    }

    private func loadActions() {
        Task {
            let actions = await availableActionsProvider.actions(for: input.type, ids: input.ids)
            switch actions {
            case .success(let actions):
                Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                    self?.update(actions: actions)
                }))
            case .failure:
                fatalError("Handle error here")
            }
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
