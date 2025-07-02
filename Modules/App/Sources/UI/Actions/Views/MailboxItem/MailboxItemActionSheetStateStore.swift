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
import InboxCoreUI
import SwiftUI
import proton_app_uniffi

class MailboxItemActionSheetStateStore: StateStore {
    @Published var state: MailboxItemActionSheetState
    private let availableActionsProvider: AvailableActionsProvider
    private let input: MailboxItemActionSheetInput
    private let starActionPerformer: StarActionPerformer
    private let readActionPerformer: ReadActionPerformer
    private let deleteActionPerformer: DeleteActionPerformer
    private let moveToActionPerformer: MoveToActionPerformer
    private let generalActionsPerformer: GeneralActionsPerformer
    private let toastStateStore: ToastStateStore
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    private let colorScheme: ColorScheme
    private let navigation: (MailboxItemActionSheetNavigation) -> Void

    init(
        input: MailboxItemActionSheetInput,
        mailbox: Mailbox,
        actionsProvider: ActionsProvider,
        starActionPerformerActions: StarActionPerformerActions,
        readActionPerformerActions: ReadActionPerformerActions,
        deleteActions: DeleteActions,
        moveToActions: MoveToActions,
        generalActions: GeneralActionsWrappers,
        mailUserSession: MailUserSession,
        toastStateStore: ToastStateStore,
        messageAppearanceOverrideStore: MessageAppearanceOverrideStore,
        colorScheme: ColorScheme,
        navigation: @escaping (MailboxItemActionSheetNavigation) -> Void
    ) {
        self.input = input
        self.availableActionsProvider = .init(actionsProvider: actionsProvider, mailbox: mailbox)
        self.starActionPerformer = .init(
            mailUserSession: mailUserSession,
            starActionPerformerActions: starActionPerformerActions
        )
        self.readActionPerformer = .init(mailbox: mailbox, readActionPerformerActions: readActionPerformerActions)
        self.deleteActionPerformer = .init(mailbox: mailbox, deleteActions: deleteActions)
        self.moveToActionPerformer = .init(mailbox: mailbox, moveToActions: moveToActions)
        self.generalActionsPerformer = .init(mailbox: mailbox, generalActions: generalActions)
        self.state = .initial(title: input.title)
        self.toastStateStore = toastStateStore
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.colorScheme = colorScheme
        self.navigation = navigation
    }

    func handle(action: MailboxItemActionSheetAction) {
        switch action {
        case .onLoad:
            loadActions()
        case .mailboxItemActionSelected(let action):
            switch action {
            case .labelAs:
                navigation(.labelAs)
            case .star:
                performAction(
                    action: starActionPerformer.star,
                    ids: [input.id],
                    itemType: input.type.inboxItemType,
                    navigation: .dismiss
                )
            case .unstar:
                performAction(
                    action: starActionPerformer.unstar,
                    ids: [input.id],
                    itemType: input.type.inboxItemType,
                    navigation: .dismiss
                )
            case .markRead:
                performAction(
                    action: readActionPerformer.markAsRead,
                    ids: [input.id],
                    itemType: input.type.inboxItemType,
                    navigation: .dismiss
                )
            case .markUnread:
                performAction(
                    action: readActionPerformer.markAsUnread,
                    ids: [input.id],
                    itemType: input.type.inboxItemType,
                    navigation: .dismissAndGoBack
                )
            case .delete:
                state = state.copy(\.alert, to: deleteConfirmationAlert)
            case .pin, .unpin:
                break
            }
        case .moveTo(let action):
            switch action {
            case .moveTo:
                navigation(.moveTo)
            case .permanentDelete:
                state = state.copy(\.alert, to: deleteConfirmationAlert)
            case .notSpam(let model), .moveToSystemFolder(let model):
                performMoveToAction(destination: model, ids: [input.id], itemType: input.type)
            }
        case .generalActionTapped(let generalAction):
            switch generalAction {
            case .print, .saveAsPdf, .viewHeaders, .viewHtml:
                toastStateStore.present(toast: .comingSoon)
            case .viewMessageInLightMode:
                messageAppearanceOverrideStore.forceLightMode(forMessageWithId: input.id)
                navigation(.dismiss)
            case .viewMessageInDarkMode:
                messageAppearanceOverrideStore.stopForcingLightMode(forMessageWithId: input.id)
                navigation(.dismiss)
            case .reportPhishing:
                let alert: AlertModel = .phishingConfirmation(action: { [weak self] action in
                    self?.handle(action: .phishingConfirmed(action))
                })

                state = state.copy(\.alert, to: alert)
            }
        case .deleteConfirmed(let action):
            state = state.copy(\.alert, to: nil)
            if case .delete = action {
                performDeleteAction(itemsIDs: [input.id], itemType: input.type)
            }
        case .phishingConfirmed(let action):
            state = state.copy(\.alert, to: nil)
            if case .confirm = action {
                performMarkPhishing(itemType: input.type)
            }
        }
    }

    // MARK: - Private

    private func performMoveToAction(
        destination: MoveToSystemFolderLocation,
        ids: [ID],
        itemType: ActionSheetItemType
    ) {
        Task {
            do {
                try await moveToActionPerformer.moveTo(
                    destinationID: destination.localId,
                    itemsIDs: ids,
                    itemType: itemType.inboxItemType
                )
                presentMoveToToast(destination: destination)
            } catch {
                presentToast(toast: .error(message: error.localizedDescription))
            }

            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.navigation(itemType.dismissNavigation)
                }))
        }
    }

    private func performDeleteAction(itemsIDs: [ID], itemType: ActionSheetItemType) {
        Task {
            await deleteActionPerformer.delete(itemsWithIDs: itemsIDs, itemType: itemType.inboxItemType)
            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.presentDeletedToast()
                    self?.navigation(itemType.dismissNavigation)
                }))
        }
    }

    private func performMarkPhishing(itemType: ActionSheetItemType) {
        Task {
            if case .ok = await generalActionsPerformer.markMessagePhishing(messageID: input.id) {
                Dispatcher.dispatchOnMain(
                    .init(block: { [weak self] in
                        self?.navigation(itemType.dismissNavigation)
                    }))
            }
        }
    }

    private func performAction(
        action: ([ID], MailboxItemType, (() -> Void)?) -> Void,
        ids: [ID],
        itemType: MailboxItemType,
        navigation: MailboxItemActionSheetNavigation
    ) {
        action(ids, itemType) {
            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.navigation(navigation)
                }))
        }
    }

    private func presentMoveToToast(destination: MoveToSystemFolderLocation) {
        presentToast(toast: .moveTo(destinationName: destination.name.humanReadable.string))
    }

    private func presentDeletedToast() {
        presentToast(toast: .deleted())
    }

    private func presentToast(toast: Toast) {
        Dispatcher.dispatchOnMain(
            .init(block: { [weak self] in
                self?.toastStateStore.present(toast: toast)
            }))
    }

    private func loadActions() {
        Task {
            let isForcingLightMode = messageAppearanceOverrideStore.isForcingLightMode(forMessageWithId: input.id)
            let themeOpts = ThemeOpts(colorScheme: colorScheme, isForcingLightMode: isForcingLightMode)
            let actions = await availableActionsProvider.actions(
                for: input.type.inboxItemType,
                id: input.id,
                themeOpts: themeOpts
            )

            Dispatcher.dispatchOnMain(
                .init(block: { [weak self] in
                    self?.update(actions: actions)
                }))
        }
    }

    private func update(actions: AvailableActions) {
        state = state.copy(\.availableActions, to: actions)
    }

    private var deleteConfirmationAlert: AlertModel {
        .deleteConfirmation(
            itemsCount: 1,
            action: { [weak self] action in self?.handle(action: .deleteConfirmed(action)) }
        )
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
}

private extension MailboxItemType {

    var dismissNavigation: MailboxItemActionSheetNavigation {
        switch self {
        case .conversation:
            return .dismissAndGoBack
        case .message:
            return .dismiss
        }
    }

}

private extension ActionSheetItemType {

    var dismissNavigation: MailboxItemActionSheetNavigation {
        switch self {
        case .conversation:
            .dismissAndGoBack
        case .message(let isStandaloneMessage):
            isStandaloneMessage ? .dismissAndGoBack : .dismiss
        }
    }

}

private extension ThemeOpts {
    init(colorScheme: ColorScheme, isForcingLightMode: Bool) {
        self.init(currentTheme: .converted(from: colorScheme), themeOverride: isForcingLightMode ? .lightMode : nil)
    }
}

private extension MailTheme {
    static func converted(from colorScheme: ColorScheme) -> Self {
        switch colorScheme {
        case .light: .lightMode
        case .dark: .darkMode
        @unknown default: .lightMode
        }
    }
}
