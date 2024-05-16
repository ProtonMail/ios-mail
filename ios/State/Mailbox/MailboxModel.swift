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
import proton_mail_uniffi
import class UIKit.UIImage

/**
 Source of truth for the Mailbox view showing mailbox items (conversations or messages).
 */
final class MailboxModel: ObservableObject {
    @ObservedObject private(set) var appRoute: AppRouteState

    @Published private(set) var state: MailboxModel.State
    @Published var attachmentPresented: AttachmentViewConfig?

    let selectionMode: SelectionModeState

    private let pageSize: Int64 = 50

    private var mailbox: Mailbox?
    private var viewMode: MailSettingsViewMode {
        mailbox?.viewMode() ?? .conversations
    }
    private var conversationLiveQuery: MailboxConversationLiveQuery?
    private var messageLiveQuery: MailboxMessageLiveQuery?
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    init(appRoute: AppRouteState = .shared, state: State = .loading, dependencies: Dependencies = .init()) {
        self.appRoute = appRoute
        self.selectionMode = SelectionModeState()
        self.state = state
        self.dependencies = dependencies

        appRoute
            .$selectedMailbox
            .sink { [weak self] value in
                Task {
                    try? await self?.updateMailboxAndFetchData(selectedMailbox: appRoute.selectedMailbox)
                }
            }
            .store(in: &cancellables)

        selectionMode
            .$hasSelectedItems
            .sink { [weak self] hasItems in
                Task {
                    await self?.readLiveQueryValues()
                }
            }
            .store(in: &cancellables)
    }

    func updateMailboxAndFetchData(selectedMailbox: SelectedMailbox) async throws {
        await updateState(.loading)
        guard let userContext = try await dependencies.appContext.userContextForActiveSession() else { return }
        mailbox = try await Mailbox(ctx: userContext, labelId: selectedMailbox.localId)
        AppLogger.log(message: "mailbox view mode: \(mailbox?.viewMode().description ?? "n/a")", category: .mailbox)
        try await initialiseLiveQuery()
    }
}

// MARK: Private

extension MailboxModel {

    private func initialiseLiveQuery() async throws {
        switch viewMode {
        case .conversations:
            self.conversationLiveQuery = try mailbox?.newConversationLiveQuery(limit: pageSize, cb: self)

        case .messages:
            self.messageLiveQuery = try mailbox?.newMessageLiveQuery(limit: pageSize, cb: self)
        }
    }

    private func readLiveQueryValues() async {
        let mailboxItems = await liveQueryMailboxItems()
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

    private func liveQueryMailboxItems() async -> [MailboxItemCellUIModel] {
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        var mailboxItems = [MailboxItemCellUIModel]()
        switch viewMode {
        case .conversations:
            guard let conversationLiveQuery else { break  }
            mailboxItems = await conversationLiveQuery.value().asyncMap { @Sendable in
                await $0.toMailboxItemCellUIModel(selectedIds: selectedIds)
            }
        case .messages:
            guard let messageLiveQuery else { break  }
            mailboxItems = await messageLiveQuery.value().asyncMap { @Sendable in
                await $0.toMailboxItemCellUIModel(selectedIds: selectedIds)
            }
        }
        return mailboxItems
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.logTemporarily(message: "updateState \(newState.debugDescription)", category: .mailbox)
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

        // navigate to conversation ...
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

    func onMailboxItemAttachmentTap(attachmentId: PMLocalAttachmentId, for item: MailboxItemCellUIModel) {
        guard !selectionMode.hasSelectedItems, let mailbox else {
            applySelectionStateChangeInstead(mailboxItem: item)
            return
        }
        attachmentPresented = AttachmentViewConfig(
            attachmentId: attachmentId,
            dataSource: AttachmentAPIDataSource(mailbox: mailbox)
        )
    }

    func onMailboxItemAction(_ action: Action, itemIds: [PMMailboxItemId]) {
        switch action {
        case .delete:
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

// MARK: MailboxLiveQueryUpdatedCallback

extension MailboxModel: MailboxLiveQueryUpdatedCallback {

    func onUpdated() {
        Task {
            await readLiveQueryValues()
        }
    }
}

// MARK: conversation actions

extension MailboxModel {

    private func actionStar(ids: [PMMailboxItemId]) {
        do {
            try mailbox?.starConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionUnstar(ids: [PMMailboxItemId]) {
        do {
            try mailbox?.unstarConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionDelete(ids: [PMMailboxItemId]) {
        AppLogger.log(message: "Conversation deletion \(ids)...", category: .mailboxActions)
        do {
            try mailbox?.deleteConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionMoveTo(systemFolder: SystemFolderIdentifier, ids: [PMMailboxItemId]) {
        Task {
            do {
                guard let userSession = try await dependencies.appContext.userContextForActiveSession() else { return }
                guard let systemFolderLocalLabel = try userSession.movableFolders().first(where: { folder in
                    guard let rid = folder.rid, let remoteId = UInt64(rid) else { return false }
                    return remoteId == systemFolder.rawValue
                }) else {
                    let message = "system folder \(systemFolder) local label id not found"
                    AppLogger.log(message: message, category: .mailboxActions, isError: true)
                    return
                }
                actionMoveTo(labelId: systemFolderLocalLabel.id, ids: ids)
            } catch {
                AppLogger.log(error: error)
            }
        }
    }

    private func actionMoveTo(labelId: PMLocalLabelId, ids: [PMMailboxItemId]) {
        do {
            try mailbox?.moveConversations(labelId: labelId, ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionUpdateReadStatus(to newStatus: MailboxReadStatus, for ids: [PMMailboxItemId]) {
        AppLogger.log(message: "Conversation set read status \(ids)...", category: .mailboxActions)
        do {
            if case .read = newStatus {
                try mailbox?.markConversationsRead(ids: ids)
            } else if case .unread = newStatus {
                try mailbox?.markConversationsUnread(ids: ids)
            }
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionApplyLabels(_ selectedLabels: Set<PMLocalLabelId>, to ids: [PMMailboxItemId]) {
        guard case .data(let conversations) = state else { return }
        let selectedConversations = conversations.filter({ $0.isSelected })
        do {
            let existingLabelsInConversations = selectedConversations
                .map(\.labelUIModel.allLabelIds)
                .reduce(Set<PMLocalLabelId>(), { $0.union($1) })
            
            try existingLabelsInConversations.forEach { labelId in
                try mailbox?.unlabelConversations(labelId: labelId, ids: selectedConversations.map(\.id))
            }

            try selectedLabels.forEach { labelId in
                try mailbox?.labelConversations(labelId: labelId, ids: selectedConversations.map(\.id))
            }
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }
}

// MARK: MailboxActionable

extension MailboxModel: MailboxActionable {
    
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>] {
        guard case .data(let items) = state else { return [] }
        return items.filter({ $0.isSelected }).map(\.labelUIModel.allLabelIds)
    }

    func onActionTap(_ action: Action) {
        onMailboxItemAction(action, itemIds: selectionMode.selectedItems.map(\.id))
    }

    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool) {
        let selectedItemIds = selectionMode.selectedItems.map(\.id)
        actionApplyLabels(labelIds, to: selectedItemIds)
        if alsoArchive {
            actionMoveTo(systemFolder: .archive, ids: selectedItemIds)
        }
    }

    func onFolderSelected(labelId: PMLocalLabelId) {
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
