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

import InboxCoreUI
import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

enum SearchScreenState {
    case initial
    case search
}

struct SearchScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.mainWindowSize) private var mainWindowSize
    @EnvironmentObject private var composerCoordinator: ComposerCoordinator
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private(set) var resultsState: SearchScreenState = .initial
    @State private(set) var isListAtTop: Bool = true
    @State private var searchedText: String = .empty
    @StateObject private var model: SearchModel
    @FocusState private var searchFocused: Bool
    private let userSession: MailUserSession

    init(
        userSession: MailUserSession,
        loadingBarPresenter: LoadingBarPresenter,
        mailSettingsLiveQuery: MailSettingLiveQuerying
    ) {
        _model = StateObject(
            wrappedValue: .init(
                loadingBarPresenter: loadingBarPresenter,
                mailSettingsLiveQuery: mailSettingsLiveQuery
            ))
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
                    VStack(spacing: .zero) {
                        if #unavailable(iOS 26) {
                            mailboxTopBarView()
                        }

                        resultsList
                            .fullScreenCover(item: $model.state.attachmentPresented) { config in
                                AttachmentView(config: config)
                                    .edgesIgnoringSafeArea([.top, .bottom])
                            }
                            .navigationDestination(for: MailboxItemCellUIModel.self) { uiModel in
                                mailboxItemDestination(uiModel: uiModel)
                            }
                            .modify { view in
                                if #available(iOS 26, *) {
                                    view
                                        .safeAreaBar(edge: .top) {
                                            mailboxTopBarView()
                                        }
                                }
                            }
                    }
                }
            }
            .modifier(SearchDismissModifier(dismiss: dismiss))
            .modify { view in
                if #available(iOS 26, *) {
                    liquidGlassSearchBar(view: view)
                } else {
                    nonLiquidGlassSearchBar(view: view)
                }
            }
            .labelAsSheet(
                mailbox: { model.mailbox },
                mailUserSession: userSession,
                input: $model.state.labelAsSheetPresented
            )
            .moveToSheet(
                mailbox: { model.mailbox },
                mailUserSession: userSession,
                input: $model.state.moveToSheetPresented,
                navigation: { _ in model.state.moveToSheetPresented = nil }
            )
            .onLoad {
                searchFocused = true

                Task {
                    await model.prepareSwipeActions()
                }
            }
        }
        .composer(screen: .search, coordinator: composerCoordinator)
    }

    private var listConfiguration: MailboxItemsListViewConfiguration {
        .init(
            dataSource: model.paginatedDataSource,
            selectionState: model.selectionMode.selectionState,
            itemTypeForActionBar: .message,
            systemLabel: model.selectedMailbox.systemFolder,
            swipeActions: model.state.swipeActions,
            listEventHandler: .init(
                listAtTop: { value in isListAtTop = value },
                pullToRefresh: nil,
            ),
            cellEventHandler: .init(
                onCellEvent: handleResultCellEvent,
                onSwipeAction: { context in
                    model.onMailboxItemAction(context, toastStateStore: toastStateStore)
                }
            )
        )
    }

    private func handleResultCellEvent(event: MailboxItemCellEvent, item: MailboxItemCellUIModel) {
        switch event {
        case .onTap:
            model.onMailboxItemTap(item: item, draftPresenter: composerCoordinator.draftPresenter)
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
        MailboxItemsListView<NoResultsView, LiquidComposeButton>(
            config: listConfiguration,
            emptyView: {
                NoResultsView(variant: .search)
            },
            emptyFolderBanner: .constant(nil),
            mailUserSession: userSession,
            mailbox: model.mailbox,
            liquidComposeButton: nil
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func mailboxItemDestination(uiModel: MailboxItemCellUIModel) -> some View {
        ConversationsPageViewController(
            startingItem: .searchResultItem(messageModel: uiModel, selectedMailbox: model.selectedMailbox),
            makeMailboxCursor: model.mailboxCursor,
            modelToSeedMapping: ConversationDetailSeed.searchResultItem,
            draftPresenter: composerCoordinator.draftPresenter,
            selectedMailbox: model.selectedMailbox,
            userSession: userSession
        )
    }

    private func nonLiquidGlassSearchBar<ParentView: View>(view: ParentView) -> some View {
        view
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchToolbarView(selectedState: model.selectionMode.selectionState, isFocused: $searchFocused) { event in
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
    }

    @available(iOS 26, *)
    private func liquidGlassSearchBar<ParentView: View>(view: ParentView) -> some View {
        view
            .searchable(
                text: $searchedText,
                placement: .navigationBarDrawer,
                prompt: Text(L10n.Search.searchPlaceholder)
            )
            .onSubmit(of: .search) {
                resultsState = .search
                model.searchText(searchedText)
            }
            .searchFocused($searchFocused)
    }

    @ViewBuilder
    private func mailboxTopBarView() -> some View {
        MailboxTopBarView(state: .includeSpamTrash(isSelected: model.state.spamTrashToggleState.isSelected)) { event in
            switch event {
            case .spamTrashToggleTapped:
                model.includeTrashSpamTapped()
            case .selectAllTapped:
                break
            }
        }
    }
}

private struct SearchDismissModifier: ViewModifier {
    @Environment(\.isSearching) private var isSearching
    let dismiss: DismissAction

    func body(content: Content) -> some View {
        content.onChange(of: isSearching) { _, newValue in
            if !newValue { dismiss() }
        }
    }
}
