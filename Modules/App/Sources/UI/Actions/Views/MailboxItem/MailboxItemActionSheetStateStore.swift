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

struct MessageActionPerformer {

}

class MailboxItemActionSheetStateStore: StateStore {
    @Published var state: MailboxItemActionSheetState
    private let availableActionsProvider: AvailableActionsProvider
    private let input: MailboxItemActionSheetInput
    private let starActionPerformer: StarActionPerformer
    private let readActionPerformer: ReadActionPerformer
    private let deleteActionPerformer: DeleteActionPerformer
    private let moveToActionPerformer: MoveToActionPerformer
    private let generalActionsPerformer: GeneralActionsPerformer
    private let mailUserSession: MailUserSession
    private let toastStateStore: ToastStateStore
    private let messageAppearanceOverrideStore: MessageAppearanceOverrideStore
    private let printActionPerformer: PrintActionPerformer
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
        printActionPerformer: PrintActionPerformer,
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
        self.mailUserSession = mailUserSession
        self.state = .initial(title: input.title, itemType: input.type)
        self.toastStateStore = toastStateStore
        self.messageAppearanceOverrideStore = messageAppearanceOverrideStore
        self.printActionPerformer = printActionPerformer
        self.colorScheme = colorScheme
        self.navigation = navigation
    }

    @MainActor
    func handle(action: MailboxItemActionSheetAction) async {
        switch action {
        case .onLoad:
            await loadActions()
        case .mailboxItemActionTapped(let action):
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
            case .snooze:
                navigation(.snooze)
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
                await performMoveToAction(destination: model, ids: [input.id], itemType: input.type)
            }
        case .generalActionTapped(let generalAction):
            switch generalAction {
            case .saveAsPdf, .viewHeaders, .viewHtml:
                toastStateStore.present(toast: .comingSoon)
            case .print:
                do {
                    try await printActionPerformer.printMessage(messageID: input.id)
                } catch {
                    AppLogger.log(error: error)
                    toastStateStore.present(toast: .error(message: error.localizedDescription))
                }
            case .viewMessageInLightMode:
                messageAppearanceOverrideStore.forceLightMode(forMessageWithId: input.id)
                navigation(.dismiss)
            case .viewMessageInDarkMode:
                messageAppearanceOverrideStore.stopForcingLightMode(forMessageWithId: input.id)
                navigation(.dismiss)
            case .reportPhishing:
                let alert: AlertModel = .phishingConfirmation(action: { [weak self] action in
                    await self?.handle(action: .phishingConfirmed(action))
                })

                state = state.copy(\.alert, to: alert)
            }
        case .deleteConfirmed(let action):
            state = state.copy(\.alert, to: nil)
            if case .delete = action {
                await performDeleteAction(itemsIDs: [input.id], itemType: input.type)
            }
        case .phishingConfirmed(let action):
            state = state.copy(\.alert, to: nil)
            if case .confirm = action {
                await performMarkPhishing(itemType: input.type)
            }
        case .editToolbarActionTapped:
            // FIXME: - Handle action
            break
        }
    }

    // MARK: - Private

    @MainActor
    private func performMoveToAction(
        destination: MoveToSystemFolderLocation,
        ids: [ID],
        itemType: ActionSheetItemType
    ) async {
        do {
            let undo = try await moveToActionPerformer.moveTo(
                destinationID: destination.localId,
                itemsIDs: ids,
                itemType: itemType.inboxItemType
            )
            let toastID = UUID()
            let undoAction = undo.undoAction(userSession: mailUserSession) { [weak self] in
                self?.dismissToast(withID: toastID)
            }
            presentMoveToToast(id: toastID, destination: destination, undoAction: undoAction)
        } catch {
            presentToast(toast: .error(message: error.localizedDescription))
        }

        navigation(itemType.dismissNavigation)
    }

    @MainActor
    private func performDeleteAction(itemsIDs: [ID], itemType: ActionSheetItemType) async {
        await deleteActionPerformer.delete(itemsWithIDs: itemsIDs, itemType: itemType.inboxItemType)
        presentDeletedToast()
        navigation(itemType.dismissNavigation)
    }

    @MainActor
    private func performMarkPhishing(itemType: ActionSheetItemType) async {
        if case .ok = await generalActionsPerformer.markMessagePhishing(messageID: input.id) {
            navigation(itemType.dismissNavigation)
        }
    }

    @MainActor
    private func performAction(
        action: ([ID], MailboxItemType, (() -> Void)?) -> Void,
        ids: [ID],
        itemType: MailboxItemType,
        navigation: MailboxItemActionSheetNavigation
    ) {
        action(ids, itemType) { [weak self] in
            self?.navigation(navigation)
        }
    }

    @MainActor
    private func presentMoveToToast(
        id: UUID,
        destination: MoveToSystemFolderLocation,
        undoAction: (() -> Void)?
    ) {
        let destinationName = destination.name.humanReadable.string
        let toast: Toast = .moveTo(id: id, destinationName: destinationName, undoAction: undoAction)
        presentToast(toast: toast)
    }

    @MainActor
    private func presentDeletedToast() {
        presentToast(toast: .deleted())
    }

    @MainActor
    private func presentToast(toast: Toast) {
        toastStateStore.present(toast: toast)
    }

    @MainActor
    private func dismissToast(withID toastID: UUID) {
        toastStateStore.dismiss(withID: toastID)
    }

    @MainActor
    private func loadActions() async {
        let actions = await availableActionsProvider.actions(
            for: input.type.inboxItemType,
            id: input.id,
            themeOpts: messageAppearanceOverrideStore.themeOpts(messageID: input.id, colorScheme: colorScheme)
        )

        update(actions: actions)
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

extension MessageAppearanceOverrideStore {

    func themeOpts(messageID: ID, colorScheme: ColorScheme) -> ThemeOpts {
        let isForcingLightMode = isForcingLightMode(forMessageWithId: messageID)
        return .init(colorScheme: colorScheme, isForcingLightMode: isForcingLightMode)
    }

}

private extension MailboxItemActionSheetState {
    static func initial(title: String, itemType: ActionSheetItemType) -> Self {
        .init(
            title: title,
            showEditToolbarAction: itemType.showEditToolbarAction,
            availableActions: .init(
                replyActions: [],
                mailboxItemActions: [],
                moveActions: [],
                generalActions: []
            )
        )
    }
}

private extension ActionSheetItemType {

    var showEditToolbarAction: Bool {
        switch self {
        case .conversation:
            true
        case .message:
            false
        }
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


extension ThemeOpts {
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
