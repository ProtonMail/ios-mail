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

import DesignSystem
import SwiftUI

struct AvailableMailboxActionBarActions {
    let message: (Mailbox, [Id]) async throws -> AllBottomBarMessageActions
}

extension AvailableMailboxActionBarActions {

    static var productionInstance: Self {
        .init(message: allAvailableBottomBarActionsForMessages)
    }

}

struct MailboxActionBarActionsProvider {
    let availableActions: AvailableMailboxActionBarActions

    func actions(for mailbox: Mailbox, ids: [ID]) async -> AllBottomBarMessageActions {
        return switch mailbox.viewMode() {
        case .messages:
            try! await availableActions.message(mailbox, ids)
        case .conversations:
            .testData
        }
    }
}

struct MailboxActionBarActionDisplayData {
    let icon: ImageResource
    let name: LocalizedStringResource?
}

struct MailboxActionBarState: Copying {
    var visibleActions: [BottomBarAction]
    var moreActions: [BottomBarAction]
    var moreActionSheetPresented: Bool
    var labelAsSheetPresented: ActionSheetInput?
    var moveToSheetPresented: ActionSheetInput?
}

enum MailboxActionBarAction {
    case mailboxItemsSelectionUpdated(Set<ID>, mailbox: Mailbox)
    case actionSelected(BottomBarAction, ids: Set<ID>, mailbox: Mailbox)
}

extension MailboxActionBarState {
    static var initial: Self {
        .init(
            visibleActions: [],
            moreActions: [],
            moreActionSheetPresented: false,
            labelAsSheetPresented: nil,
            moveToSheetPresented: nil
        )
    }
}

class MailboxActionBarStateStore: ObservableObject {
    @Published var state: MailboxActionBarState
    private let actionsProvider: MailboxActionBarActionsProvider

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions
    ) {
        self.state = state
        self.actionsProvider = .init(availableActions: availableActions)
    }

    func handle(action: MailboxActionBarAction) {
        switch action {
        case .mailboxItemsSelectionUpdated(let ids, let mailbox):
            fetchAvailableBottomBarActions(for: ids, mailbox: mailbox)
        case .actionSelected(let action, let ids, let mailbox):
            handle(action: action, ids: ids, mailbox: mailbox)
        }
    }

    // MARK: - Private

    private func handle(action: BottomBarAction, ids: Set<ID>, mailbox: Mailbox) {
        switch action {
        case .more:
            state = state.copy(\.moreActionSheetPresented, to: true)
        case .labelAs:
            state = state.copy(\.labelAsSheetPresented, to: .init(ids: Array(ids), type: mailbox.viewMode().itemType))
        case .moveTo:
            state = state.copy(\.moveToSheetPresented, to: .init(ids: Array(ids), type: mailbox.viewMode().itemType))
        default:
            break // FIXME: - Handle rest of the actions
        }
    }

    private func fetchAvailableBottomBarActions(for ids: Set<ID>, mailbox: Mailbox) {
        guard !ids.isEmpty else { return }
        Task {
            let actions = await actionsProvider.actions(for: mailbox, ids: Array(ids))
            Dispatcher.dispatchOnMain(.init(block: { [weak self] in
                self?.updateActions(actions: actions)
            }))
        }
    }

    private func updateActions(actions: AllBottomBarMessageActions) {
        state = state
            .copy(\.visibleActions, to: actions.visibleBottomBarActions.compactMap(\.action))
            .copy(\.moreActions, to: actions.hiddenBottomBarActions.compactMap(\.action))
    }
}

struct MailboxActionBarView: View {
    @Binding var selectedItems: Set<ID>
    @EnvironmentObject var mailbox: Mailbox
    @StateObject var store: MailboxActionBarStateStore

    init(
        state: MailboxActionBarState,
        availableActions: AvailableMailboxActionBarActions,
        selectedItems: Binding<Set<ID>>
    ) {
        self._selectedItems = selectedItems
        self._store = StateObject(wrappedValue: .init(state: state, availableActions: availableActions))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    ForEach(store.state.visibleActions, id: \.self) { action in
                        Button(action: { }) {
                            Image(action.displayModel.icon)
                                .foregroundStyle(DS.Color.Icon.weak)
                        }
                        Spacer()
                    }
                }
                .frame(
                    width: min(geometry.size.width, geometry.size.height), 
                    height: 45 + geometry.safeAreaInsets.bottom
                )
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .compositingGroup()
                .shadow(radius: 2)
                .tint(DS.Color.Text.norm)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(MailboxActionBarViewIdentifiers.rootItem)
                .onChange(of: selectedItems) { oldValue, newValue in
                    if oldValue != newValue {
                        store.handle(action: .mailboxItemsSelectionUpdated(newValue, mailbox: mailbox))
                    }
                }
            }
        }
    }
}

#Preview {
    let state = MailboxActionBarState(
        visibleActions: [
            .markRead,
            .moveTo,
            .labelAs,
            .moveToSystemFolder(MoveToSystemFolderLocation(localId: .init(value: 1), systemLabel: .archive)), 
            .more
        ],
        moreActions: [.notSpam, .permanentDelete, .star],
        moreActionSheetPresented: false,
        labelAsSheetPresented: nil,
        moveToSheetPresented: nil
    )
    return MailboxActionBarView(
        state: state,
        availableActions: .init(message: { _, _ in
            AllBottomBarMessageActions(
                hiddenBottomBarActions: [],
                visibleBottomBarActions: [.markRead, .star, .moveTo, .labelAs, .more]
            )
        }),
        selectedItems: .constant([])
    )
}

extension AllBottomBarMessageActions {

    static var testData: Self {
        .init(
            hiddenBottomBarActions: [.notSpam, .permanentDelete, .moveToSystemFolder(.archive)],
            visibleBottomBarActions: [.markRead, .star, .moveTo, .labelAs, .more]
        )
    }

}

// MARK: Accessibility

private struct MailboxActionBarViewIdentifiers {
    static let rootItem = "mailbox.actionBar.rootItem"
    static let button1 = "mailbox.actionBar.button1"
    static let button2 = "mailbox.actionBar.button2"
    static let button3 = "mailbox.actionBar.button3"
    static let button4 = "mailbox.actionBar.button4"
    static let button5 = "mailbox.actionBar.button5"
}

import proton_app_uniffi
import ProtonCoreUI

extension SystemLabel {

    var moveToSystemFolder: MoveToSystemFolderLocation? {
        switch self {
        case .inbox:
            return .init(localId: .init(value: 1), systemLabel: .inbox)
        case .trash:
            return .init(localId: .init(value: 2), systemLabel: .trash)
        case .spam:
            return .init(localId: .init(value: 3), systemLabel: .spam)
        case .archive:
            return .init(localId: .init(value: 4), systemLabel: .archive)
        case .sent, .allMail, .allDrafts, .allSent, .drafts, .outbox, .starred, .scheduled, .almostAllMail,
                .snoozed, .categorySocial, .categoryPromotions, .catergoryUpdates, .categoryForums, .categoryDefault:
            return nil
        }
    }

}

extension BottomBarActions {

    var action: BottomBarAction? {
        switch self {
        case .labelAs:
            return .labelAs
        case .markRead:
            return .markRead
        case .markUnread:
            return .markUnread
        case .more:
            return .more
        case .moveTo:
            return .moveTo
        case .moveToSystemFolder(let label):
            return label.moveToSystemFolder.map(BottomBarAction.moveToSystemFolder)
        case .notSpam:
            return .notSpam
        case .permanentDelete:
            return .permanentDelete
        case .star:
            return .star
        case .unstar:
            return .unstar
        }
    }

}

enum BottomBarAction: Hashable {
    case labelAs
    case markRead
    case markUnread
    case more
    case moveTo
    case moveToSystemFolder(MoveToSystemFolderLocation)
    case notSpam
    case permanentDelete
    case star
    case unstar
}

extension BottomBarAction {

    var displayModel: MailboxActionBarActionDisplayData {
        switch self {
        case .labelAs:
            return .init(icon: DS.Icon.icTag, name: L10n.Action.labelAs)
        case .markRead:
            return .init(icon: DS.Icon.icEnvelopeOpen, name: L10n.Action.markAsRead)
        case .markUnread:
            return .init(icon: DS.Icon.icEnvelopeDot, name: L10n.Action.markAsUnread)
        case .more:
            return .init(icon: DS.Icon.icThreeDotsHorizontal, name: nil)
        case .moveTo:
            return .init(icon: DS.Icon.icFolderArrowIn, name: L10n.Action.moveTo)
        case .moveToSystemFolder(let systemFolder):
            switch systemFolder.systemLabel {
            case .archive:
                return .init(icon: DS.Icon.icArchiveBox, name: L10n.Action.moveToArchive)
            case .inbox:
                return .init(icon: DS.Icon.icInbox, name: L10n.Action.moveToInbox)
            case .spam:
                return .init(icon: DS.Icon.icSpam, name: L10n.Action.moveToSpam)
            case .trash:
                return .init(icon: DS.Icon.icTrash, name: L10n.Action.moveToTrash)
            }
        case .notSpam:
            return .init(icon: DS.Icon.icNotSpam, name: "Not spam")
        case .permanentDelete:
            return .init(icon: DS.Icon.icTrashCross, name: L10n.Action.deletePermanently)
        case .star:
            return .init(icon: DS.Icon.icStar, name: L10n.Action.star)
        case .unstar:
            return .init(icon: DS.Icon.icStarSlash, name: L10n.Action.unstar)
        }
    }

}

extension Mailbox: ObservableObject {}

extension ViewMode {

    var itemType: MailboxItemType {
        switch self {
        case .conversations:
            return .conversation
        case .messages:
            return .message
        }
    }

}
