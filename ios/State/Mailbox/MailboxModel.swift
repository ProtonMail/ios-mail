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
import Foundation
import SwiftUI
import proton_app_uniffi
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
final class MailboxModel: ObservableObject {
    @ObservedObject private var appRoute: AppRouteState
    @Published private(set) var state: MailboxModel.State
    
    // Filter
    @Published var unreadItemsCount: UInt64 = 0
    @Published var isUnreadSelected: Bool = false

    // Navigation properties
    @Published var attachmentPresented: AttachmentViewConfig?
    @Published var navigationPath: NavigationPath = .init()

    let selectionMode: SelectionModeState

    var viewMode: ViewMode {
        mailbox?.viewMode() ?? .conversations
    }

    private let pageSize: Int64 = 50
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private(set) var selectedMailbox: SelectedMailbox
    private var mailbox: Mailbox?
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()
    private var itemsCountLiveQuery: ItemsCountLiveQuery?
    private let itemListCallback: PMMailboxLiveQueryUpdatedCallback = .init(delegate: {})
    private var handle: WatchHandle?

    private var userSession: MailUserSession {
        dependencies.appContext.userSession
    }

    init(
        state: State = .loading,
        mailSettingsLiveQuery: MailSettingLiveQuerying,
        appRoute: AppRouteState,
        openedItem: MailboxMessageSeed? = nil,
        dependencies: Dependencies = .init()
    ) {
        AppLogger.log(message: "MailboxModel init", category: .mailbox)
        self.state = state
        self.mailSettingsLiveQuery = mailSettingsLiveQuery
        self.appRoute = appRoute
        self.selectedMailbox = appRoute.route.selectedMailbox ?? .inbox
        self.selectionMode = SelectionModeState()
        self.dependencies = dependencies

        setUpBindings()
        setUpWatchedMailboxItemsCallback()

        if let openedItem = openedItem {
            navigationPath.append(openedItem)
        }
    }

    deinit {
        AppLogger.log(message: "MailboxModel deinit", category: .mailbox)
    }

    func onViewDidAppear() async {
        await updateMailboxAndFetchData()
    }
}

// MARK: Private

extension MailboxModel {

    private func setUpBindings() {
        appRoute
            .onSelectedMailboxChange
            .sink { [weak self] newSelectedMailbox in
                Task {
                    guard let self else { return }
                    self.selectedMailbox = newSelectedMailbox
                    await self.updateMailboxAndFetchData()
                }
            }
            .store(in: &cancellables)

        mailSettingsLiveQuery
            .settingsPublisher
            .map(\.viewMode)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    guard let self else { return }
                    AppLogger.log(message: "viewMode has changed", category: .mailbox)
                    await self.updateMailboxAndFetchData()
                }
            }
            .store(in: &cancellables)

        selectionMode
            .$hasSelectedItems
            .sink { [weak self] hasItems in
                Task {
                    await self?.readMailboxItems()
                }
            }
            .store(in: &cancellables)
    }

    private func setUpWatchedMailboxItemsCallback() {
        itemListCallback.delegate = { [weak self] in
            AppLogger.logTemporarily(message: "item list callback", category: .mailbox)
            guard let self else { return }
            Task {
                await self.readMailboxItems()
            }
        }
    }

    /// Call this function to reset the Mailbox object with a new label id and fetch its mailbox items
    private func updateMailboxAndFetchData() async {
        await updateState(.loading)
        guard let userSession = dependencies.appContext.activeUserSession else { return }
        do {
            let mailbox = selectedMailbox.isInbox
            ? try await Mailbox.inbox(ctx: userSession)
            : try await Mailbox(ctx: userSession, labelId: selectedMailbox.localId)
            self.mailbox = mailbox

            AppLogger.log(message: "mailbox view mode: \(mailbox.viewMode().description)", category: .mailbox)
            try await createWatchHandler(for: mailbox.labelId())
            await readMailboxItems()
        } catch {
            AppLogger.log(error: error, category: .mailbox)
        }
    }
    
    /// Keeps a reference to the `WatchHandler` that will trigger a callback when there are changes to the mailbox items
    private func createWatchHandler(for labelId: ID) async throws {
        switch viewMode {
        case .conversations:
            handle = try await watchConversationsForLabel(
                session: userSession,
                labelId: labelId,
                callback: itemListCallback
            ).handle
        case .messages:
            handle = try await watchMessagesForLabel(
                session: userSession,
                labelId: labelId,
                callback: itemListCallback
            ).handle
        }
    }

    private func readMailboxItems() async {
        guard let mailbox else {
            AppLogger.log(message: "No mailbox object found", category: .mailbox, isError: true)
            return
        }
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        var mailboxItems = [MailboxItemCellUIModel]()
        do {
            switch viewMode {
            case .conversations:
                mailboxItems = try await conversationsForLabel(session: userSession, labelId: mailbox.labelId())
                    .map { conversation in
                        conversation.toMailboxItemCellUIModel(selectedIds: selectedIds)
                    }

            case .messages:
                let systemFolder = selectedMailbox.systemFolder
                mailboxItems = try await messagesForLabel(session: userSession, labelId: mailbox.labelId())
                    .asyncMap { @Sendable message in
                        let mapRecipientsAsSender = [SystemFolderLabel.drafts, .allDrafts, .sent, .allSent, .scheduled]
                            .contains(systemFolder)
                        return message.toMailboxItemCellUIModel(
                            selectedIds: selectedIds,
                            mapRecipientsAsSender: mapRecipientsAsSender
                        )
                    }
            }
        }
        catch {
            AppLogger.log(error: error, category: .mailbox)
        }
        let newState: State = mailboxItems.count > 0 ? .data(mailboxItems) : .empty
        await updateState(newState)

        selectionMode.refreshSelectedItemsStatus { itemIds in
            guard !itemIds.isEmpty, case .data(let mailboxItems) = state else { return [] }
            let selectedItems = mailboxItems
                .filter { itemIds.contains($0.id) }
                .map { $0.toSelectedItem() }
            return Set(selectedItems)
        }
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.logTemporarily(message: "mailbox update state \(newState.debugDescription)", category: .mailbox)
        state = newState
    }
}

// MARK: View actions

extension MailboxModel {

    private func applySelectionStateChangeInstead(mailboxItem: MailboxItemCellUIModel) {
        let isCurrentlySelected = selectionMode.selectedItems.contains(mailboxItem.toSelectedItem())
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: !isCurrentlySelected)
    }

    @MainActor
    func onMailboxItemTap(item: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        navigationPath.append(item)
    }

    @MainActor
    func onLongPress(mailboxItem: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems else { return }
        onMailboxItemSelectionChange(item: mailboxItem, isSelected: true)
    }

    @MainActor
    func onMailboxItemSelectionChange(item: MailboxItemCellUIModel, isSelected: Bool) {
        isSelected
        ? selectionMode.addMailboxItem(item.toSelectedItem())
        : selectionMode.removeMailboxItem(item.toSelectedItem())
    }

    func onMailboxItemStarChange(item: MailboxItemCellUIModel, isStarred: Bool) {
        guard !selectionMode.hasSelectedItems else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        isStarred ? actionStar(ids: [item.id]) : actionUnstar(ids: [item.id])
    }

    func onMailboxItemAttachmentTap(attachmentId: ID, for item: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        attachmentPresented = AttachmentViewConfig(id: attachmentId, mailbox: mailbox)
    }

    func onMailboxItemAction(_ action: Action, itemIds: [ID]) {
        switch action {
        case .deletePermanently:
            actionDelete(ids: itemIds)
        case .markAsRead:
            actionUpdateReadStatus(to: .read, for: itemIds)
        case .markAsUnread:
            actionUpdateReadStatus(to: .unread, for: itemIds)
        case .moveToArchive:
            actionMoveTo(systemFolder: .archive, ids: itemIds)
        case .moveToInbox:
            actionMoveTo(systemFolder: .inbox, ids: itemIds)
        case .moveToSpam:
            actionMoveTo(systemFolder: .spam, ids: itemIds)
        case .moveToTrash:
            actionMoveTo(systemFolder: .trash, ids: itemIds)
        case .star:
            actionStar(ids: itemIds)
        case .unstar:
            actionUnstar(ids: itemIds)
        default:
            break
        }
    }
}

// MARK: conversation actions

extension MailboxModel {

    private func actionStar(ids: [ID]) {
        Task {
            do {
                try await starConversations(session: userSession, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionUnstar(ids: [ID]) {
        Task {
            do {
                try await unstarConversations(session: userSession, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionDelete(ids: [ID]) {
        AppLogger.log(message: "Conversation deletion \(ids)...", category: .mailboxActions)
        guard let mailbox else { return }
        Task {
            do {
                try await deleteConversations(mailbox: mailbox, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionMoveTo(systemFolder: SystemFolderLabel, ids: [ID]) {
        actionMoveTo(labelId: .init(value: UInt64(systemFolder.rawValue)), ids: ids)
    }

    private func actionMoveTo(labelId: ID, ids: [ID]) {
        guard let mailbox else { return }
        Task {
            do {
                try await moveConversations(mailbox: mailbox, labelId: labelId, ids: ids)
            } catch {
                AppLogger.log(error: error, category: .mailboxActions)
            }
        }
    }

    private func actionUpdateReadStatus(to newStatus: MailboxReadStatus, for ids: [ID]) {
        AppLogger.log(message: "Conversation set read status \(ids)...", category: .mailboxActions)
        do {
            if case .read = newStatus {
                Task {
                    do {
                        try await markConversationsAsRead(session: userSession, ids: ids)
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            } else if case .unread = newStatus {
                Task {
                    do {
                        try await markConversationsAsUnread(session: userSession, ids: ids)
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            }
        }
    }

    private func actionApplyLabels(_ selectedLabels: Set<ID>, to ids: [ID]) {
        guard case .data(let conversations) = state else { return }
        let selectedConversations = conversations.filter({ $0.isSelected })
        do {
            let existingLabelsInConversations = selectedConversations
                .map(\.labelUIModel.allLabelIds)
                .reduce(Set<ID>(), { $0.union($1) })

            existingLabelsInConversations.forEach { labelId in
                Task {
                    do {
                        try await removeLabelFromConversations(
                            session: userSession,
                            labelId: labelId,
                            ids: selectedConversations.map(\.id)
                        )
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            }

            selectedLabels.forEach { labelId in
                Task {
                    do {
                        try await applyLabelToConversations(
                            session: userSession,
                            labelId: labelId,
                            ids: selectedConversations.map(\.id)
                        )
                    } catch {
                        AppLogger.log(error: error, category: .mailboxActions)
                    }
                }
            }
        }
    }
}

// MARK: MailboxActionable

extension MailboxModel: MailboxActionable {
    
    func labelsOfSelectedItems() -> [Set<ID>] {
        guard case .data(let items) = state else { return [] }
        return items.filter({ $0.isSelected }).map(\.labelUIModel.allLabelIds)
    }

    func onActionTap(_ action: Action) {
        onMailboxItemAction(action, itemIds: selectionMode.selectedItems.map(\.id))
    }

    func onLabelsSelected(labelIds: Set<ID>, alsoArchive: Bool) {
        let selectedItemIds = selectionMode.selectedItems.map(\.id)
        actionApplyLabels(labelIds, to: selectedItemIds)
        if alsoArchive {
            actionMoveTo(systemFolder: .archive, ids: selectedItemIds)
        }
    }

    func onFolderSelected(labelId: ID) {
        actionMoveTo(labelId: labelId, ids: selectionMode.selectedItems.map(\.id))
    }
}

extension MailboxModel {

    enum State: Sendable {
        case loading
        case empty
        case data([MailboxItemCellUIModel])

        var mailboxItems: [MailboxItemCellUIModel] {
            switch self {
            case .data(let items): return items
            case .empty, .loading: return []
            }
        }

        var debugDescription: String {
            if case .data(let array) = self {
                return "data \(array.count) mailbox items"
            }
            return "\(self)"
        }
    }
}

extension MailboxModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
