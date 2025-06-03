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

import InboxComposer
import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

enum SearchScreenState {
    case initial
    case search
}

struct SearchScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.mainWindowSize) private var mainWindowSize
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private(set) var resultsState: SearchScreenState = .initial
    @StateObject private var model: SearchModel
    @FocusState var isTextFieldFocused: Bool
    @State private var modalState: ModalState?
    @State private var searchDraftPresenter: DraftPresenter
    @State private var sendResultPresenter: SendResultPresenter
    @State private var makeModalScreen: (ModalState) -> ComposerScreen
    private let userSession: MailUserSession

    init(userSession: MailUserSession, sendResultPresenter: SendResultPresenter) {
        self._model = StateObject(wrappedValue: .init())
        self._searchDraftPresenter = State(
            initialValue: DraftPresenter(
                userSession: userSession,
                draftProvider: .productionInstance,
                undoSendProvider: .productionInstance(userSession: userSession),
                undoScheduleSendProvider: .productionInstance(userSession: userSession)
            )
        )
        self._makeModalScreen = .init(initialValue: { state in
            switch state {
            case .draft(let composerParams):
                ComposerScreenFactory.makeComposer(userSession: userSession, composerParams: composerParams)
            }
        })
        self._sendResultPresenter = .init(initialValue: sendResultPresenter)
        self.userSession = userSession
    }

    var body: some View {
        NavigationStack(path: $model.state.navigationPath) {
            ZStack {
                DS.Color.Background.norm
                    .ignoresSafeArea()

                switch resultsState {
                case .initial:
                    EmptyView()
                case .search:
                    resultsList
                        .fullScreenCover(item: $model.state.attachmentPresented) { config in
                            AttachmentView(config: config)
                                .edgesIgnoringSafeArea([.top, .bottom])
                        }
                        .navigationDestination(for: MailboxItemCellUIModel.self) { uiModel in
                            mailboxItemDestination(uiModel: uiModel)
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchToolbarView(selectedState: model.selectionMode.selectionState, isFocused: $isTextFieldFocused) { event in
                        switch event {
                        case .onSubmitSearch(let query):
                            resultsState = .search
                            model.searchText(query)
                        case .onCancel:
                            dismiss.callAsFunction()
                        case .onExitSelection:
                            model.selectionMode.selectionModifier.exitSelectionMode()
                        }
                    }
                    // The fix for the issue with shrinking search bar in toolbar
                    // https://protonag.atlassian.net/browse/ET-1646
                    .frame(width: 0.95 * mainWindowSize.width, height: 46)
                }
            }
            .onLoad {
                isTextFieldFocused = true
            }
        }
        .onReceive(searchDraftPresenter.draftToPresent) { modalState = modalStateFor(draftToPresent: $0) }
        .sheet(item: $modalState, content: makeModalScreen)
    }

    private func modalStateFor(draftToPresent: DraftToPresent) -> ModalState {
        .draft(
            ComposerParams(
                draftToPresent: draftToPresent,
                onDismiss: { event in
                    switch event {
                    case .messageSent(let messageId), .messageScheduled(let messageId):
                        guard let toastType = event.sendResultToastType else { return }
                        sendResultPresenter.presentResultInfo(.init(messageId: messageId, type: toastType))
                    case .dismissedManually, .draftDiscarded:
                        // TODO: Unify logic with HomeScreen. Also fix the unreported bug with the error:
                        // Currently, only presenting a single sheet is supported.
                        // The next sheet will be presented when the currently presented sheet gets dismissed.

                        toastStateStore.present(toast: .comingSoon)
                    }
                })
        )
    }

    private var listConfiguration: MailboxItemsListViewConfiguration {
        .init(
            dataSource: model.paginatedDataSource,
            selectionState: model.selectionMode.selectionState,
            itemTypeForActionBar: .message,
            isOutboxLocation: false,
            cellEventHandler: .init(onCellEvent: handleResultCellEvent)
        )
    }

    private func handleResultCellEvent(event: MailboxItemCellEvent, item: MailboxItemCellUIModel) {
        switch event {
        case .onTap:
            model.onMailboxItemTap(item: item)
        case .onLongPress:
            model.onLongPress(mailboxItem: item)
        case .onSelectedChange(let isSelected):
            model.onMailboxItemSelectionChange(item: item, isSelected: isSelected)
        case .onStarredChange(let isStarred):
            model.onMailboxItemStarChange(item: item, isStarred: isStarred)
        case .onAttachmentTap(let attachmentID):
            model.onMailboxItemAttachmentTap(attachmentId: attachmentID, for: item)
        }
    }

    private var resultsList: some View {
        MailboxItemsListView(
            config: listConfiguration,
            emptyView: {
                NoResultsView(variant: .search)
            },
            emptyFolderBanner: .constant(nil),
            mailUserSession: userSession
        )
        .injectIfNotNil(model.mailbox)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func mailboxItemDestination(uiModel: MailboxItemCellUIModel) -> some View {
        ConversationDetailScreen(
            seed: .mailboxItem(item: uiModel, selectedMailbox: model.selectedMailbox),
            draftPresenter: searchDraftPresenter,
            navigationPath: $model.state.navigationPath
        )
    }
}

private extension SearchScreen {

    enum ModalState: Identifiable {
        case draft(ComposerParams)

        var id: String {
            switch self {
            case .draft: "draft"
            }
        }
    }
}
