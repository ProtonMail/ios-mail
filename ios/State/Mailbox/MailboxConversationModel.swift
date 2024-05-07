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
 Source of truth for the Mailbox view showing conversations.
 */
final class MailboxConversationModel: ObservableObject {
    @ObservedObject private(set) var appRoute: AppRouteState
    @ObservedObject private(set) var selectionMode: SelectionModeState

    @Published private(set) var state: MailboxConversationModel.State

    private var mailbox: Mailbox?
    private var liveQuery: MailboxConversationLiveQuery?
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    init(appRoute: AppRouteState, selectionMode: SelectionModeState, state: State = .loading, dependencies: Dependencies = .init()) {
        self.appRoute = appRoute
        self.selectionMode = selectionMode
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
                    await self?.updateData()
                }
            }
            .store(in: &cancellables)
    }

    func updateMailboxAndFetchData(selectedMailbox: SelectedMailbox) async throws {
        guard let userContext = try await dependencies.appContext.userContextForActiveSession() else { return }
        mailbox = try await Mailbox(ctx: userContext, labelId: selectedMailbox.localId)
        await fetchData()
    }
}

// MARK: Private

extension MailboxConversationModel {

    private func fetchData() async {
        do {
            await updateState(.loading)
            try await fetchConversations()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }

    private func fetchConversations() async throws {
        self.liveQuery = mailbox?.newConversationLiveQuery(limit: 50, cb: self)
        await updateData()
    }

    private func updateData() async {
        guard let liveQuery else { return }
        let selectedIds = Set(selectionMode.selectedItems.map(\.id))
        let conversations = await liveQuery.value().asyncMap { @Sendable in
            await $0.toMailboxConversationCellUIModel(selectedIds: selectedIds)
        }
        let newState: State = conversations.count > 0 ? .data(conversations) : .empty
        await updateState(newState)
        selectionMode.refreshSelectedItemsStatus { itemIds in
            guard !itemIds.isEmpty, case .data(let conversations) = state else { return [] }
            let selectedItems = conversations
                .filter { itemIds.contains($0.id) }
                .map { $0.toSelectedItem() }
            return Set(selectedItems)
        }
    }

    @MainActor
    private func updateState(_ newState: State) async {
        AppLogger.logTemporarily(message: "updateState \(newState.debugDescription)", category: .mailboxConversations)
        state = newState
    }
}

// MARK: View actions

extension MailboxConversationModel {

    @MainActor
    func onConversationTap(conversation: MailboxConversationCellUIModel) {
        if selectionMode.hasSelectedItems {
            let isCurrentlySelected = selectionMode.selectedItems.contains(conversation.toSelectedItem())
            onConversationSelectionChange(conversation: conversation, isSelected: !isCurrentlySelected)
        } else {
            // ...
        }
    }

    @MainActor
    func onLongPress(conversation: MailboxConversationCellUIModel) {
        guard !selectionMode.hasSelectedItems else { return }
        onConversationSelectionChange(conversation: conversation, isSelected: true)
    }

    @MainActor
    func onConversationSelectionChange(conversation: MailboxConversationCellUIModel, isSelected: Bool) {
        isSelected
        ? selectionMode.addMailboxItem(conversation.toSelectedItem())
        : selectionMode.removeMailboxItem(conversation.toSelectedItem())
    }

    func onConversationStarChange(id: PMLocalConversationId, isStarred: Bool) {
        isStarred ? actionStar(ids: [id]) : actionUnstar(ids: [id])
    }

    func onConversationAttachmentTap(attachmentId: String) {
        print("Attachment tapped \(attachmentId)")
    }

    func onConversationAction(_ action: Action, conversationIds: [PMLocalConversationId]) {
        switch action {
        case .delete:
            actionDelete(ids: conversationIds)
        case .markAsRead:
            actionUpdateReadStatus(to: .read, for: conversationIds)
        case .markAsUnread:
            actionUpdateReadStatus(to: .unread, for: conversationIds)
        case .moveToArchive:
            actionMoveTo(systemFolder: .archive, ids: conversationIds)
        case .moveToInbox:
            actionMoveTo(systemFolder: .inbox, ids: conversationIds)
        case .moveToSpam:
            actionMoveTo(systemFolder: .spam, ids: conversationIds)
        case .moveToTrash:
            actionMoveTo(systemFolder: .trash, ids: conversationIds)
        case .star:
            actionStar(ids: conversationIds)
        case .unstar:
            actionUnstar(ids: conversationIds)
        default:
            break
        }
    }
}

// MARK: MailboxLiveQueryUpdatedCallback

extension MailboxConversationModel: MailboxLiveQueryUpdatedCallback {

    func onUpdated() {
        Task {
            await updateData()
        }
    }
}

// MARK: conversation actions

extension MailboxConversationModel {

    private func actionStar(ids: [PMLocalConversationId]) {
        do {
            try mailbox?.starConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionUnstar(ids: [PMLocalConversationId]) {
        do {
            try mailbox?.unstarConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionDelete(ids: [PMLocalConversationId]) {
        AppLogger.log(message: "Conversation deletion \(ids)...", category: .mailboxActions)
        do {
            try mailbox?.deleteConversations(ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionMoveTo(systemFolder: SystemFolderIdentifier, ids: [PMLocalConversationId]) {
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

    private func actionMoveTo(labelId: PMLocalLabelId, ids: [PMLocalConversationId]) {
        do {
            try mailbox?.moveConversations(labelId: labelId, ids: ids)
        } catch {
            AppLogger.log(error: error, category: .mailboxActions)
        }
    }

    private func actionUpdateReadStatus(to newStatus: MailboxReadStatus, for ids: [PMLocalConversationId]) {
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

    private func actionApplyLabels(_ selectedLabels: Set<PMLocalLabelId>, to ids: [PMLocalConversationId]) {
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

// MARK: MailboxActionnable

extension MailboxConversationModel: MailboxActionable {
    
    func labelsOfSelectedItems() -> [Set<PMLocalLabelId>] {
        guard case .data(let conversations) = state else { return [] }
        return conversations.filter({ $0.isSelected }).map(\.labelUIModel.allLabelIds)
    }

    func onActionTap(_ action: Action) {
        onConversationAction(action, conversationIds: selectionMode.selectedItems.map(\.id))
    }

    func onLabelsSelected(labelIds: Set<PMLocalLabelId>, alsoArchive: Bool) {
        let selectedConversationIds = selectionMode.selectedItems.map(\.id)
        actionApplyLabels(labelIds, to: selectedConversationIds)
        if alsoArchive {
            actionMoveTo(systemFolder: .archive, ids: selectedConversationIds)
        }
    }

    func onFolderSelected(labelId: PMLocalLabelId) {
        actionMoveTo(labelId: labelId, ids: selectionMode.selectedItems.map(\.id))
    }
}

extension MailboxConversationModel {

    enum State: Sendable {
        case loading
        case empty
        case data([MailboxConversationCellUIModel])

        var conversations: [MailboxConversationCellUIModel] {
            switch self {
            case .data(let conversations): return conversations
            case .empty, .loading: return []
            }
        }

        var debugDescription: String {
            if case .data(let array) = self {
                return "data \(array.count) conversations"
            }
            return "\(self)"
        }
    }
}

extension MailboxConversationModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
